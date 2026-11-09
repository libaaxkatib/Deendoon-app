import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/attachments/data/attachment_api.dart';
import 'package:mobile/features/attachments/data/attachment_repository.dart';

/// Stands in for the network: answers every request with a canned response
/// and records what was sent. Nothing is mocked above Dio, so the real
/// multipart building, status handling and response parsing are exercised.
class _FakeAdapter implements HttpClientAdapter {
  final int status;
  final String body;
  final String contentType;
  final requests = <RequestOptions>[];

  _FakeAdapter(
    this.status,
    this.body, {
    this.contentType = 'application/json; charset=utf-8',
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    // A real adapter reads the whole body; leaving the multipart stream
    // unread would keep the picked file open and block its cleanup.
    await requestStream?.drain<void>();
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _created = {
  'success': true,
  'message': 'Attachment uploaded successfully',
  'data': {
    'id': '01ATT',
    'debt_id': '01DEBT',
    'uploaded_by_user_id': '01USER',
    'original_filename': 'receipt.pdf',
    'mime_type': 'application/pdf',
    'file_size': 2048,
    'description': null,
    'created_at': '2026-11-09T05:16:04.000000Z',
  },
};

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('attachment_api_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<String> fileOfSize(int bytes) async {
    final file = File('${tempDir.path}/receipt.pdf');
    await file.writeAsBytes(Uint8List(bytes));
    return file.path;
  }

  AttachmentRepository repositoryWith(_FakeAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'))
      ..httpClientAdapter = adapter;
    return AttachmentRepository(AttachmentApi(dio));
  }

  Future<void> expectRejected(
    _FakeAdapter adapter,
    String path, {
    required String message,
    int? statusCode,
  }) async {
    await expectLater(
      repositoryWith(adapter).uploadAttachment(
        entityPathPrefix: 'debts/01DEBT',
        filePath: path,
        fileName: 'receipt.pdf',
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', message)
            .having((e) => e.statusCode, 'statusCode', statusCode),
      ),
    );
  }

  group('upload success', () {
    test(
      'posts the file as multipart to the entity path and parses 201',
      () async {
        final adapter = _FakeAdapter(201, jsonEncode(_created));

        final attachment = await repositoryWith(adapter).uploadAttachment(
          entityPathPrefix: 'debts/01DEBT',
          filePath: await fileOfSize(2048),
          fileName: 'receipt.pdf',
          description: 'Proof of delivery',
        );

        expect(attachment.id, '01ATT');
        expect(attachment.entityId, '01DEBT');
        expect(attachment.fileSize, 2048);
        final request = adapter.requests.single;
        expect(request.method, 'POST');
        expect(request.path, 'debts/01DEBT/attachments');
        expect(request.data, isA<FormData>());
        final form = request.data as FormData;
        expect(form.files.single.key, 'file');
        expect(form.files.single.value.filename, 'receipt.pdf');
        expect(form.fields.single.key, 'description');
        expect(form.fields.single.value, 'Proof of delivery');
      },
    );

    test('a file exactly at the 10 MB limit is still sent', () async {
      final adapter = _FakeAdapter(201, jsonEncode(_created));

      await repositoryWith(adapter).uploadAttachment(
        entityPathPrefix: 'debts/01DEBT',
        filePath: await fileOfSize(AttachmentApi.maxFileBytes),
        fileName: 'receipt.pdf',
      );

      expect(adapter.requests, hasLength(1));
    });
  });

  group('upload failures', () {
    test('a file over 10 MB is refused before anything is sent', () async {
      final adapter = _FakeAdapter(201, jsonEncode(_created));

      await expectRejected(
        adapter,
        await fileOfSize(AttachmentApi.maxFileBytes + 1),
        message:
            'This file is larger than 10 MB. Please choose a smaller file.',
      );

      expect(adapter.requests, isEmpty);
    });

    // Exactly what production answered for a 57 MB / 118 MB body before the
    // fix: HTTP 200, text/html, PHP's own warning and no JSON.
    test(
      'a 200 text/html body is reported, not mistaken for a success',
      () async {
        final adapter = _FakeAdapter(
          200,
          '<br />\n<b>Warning</b>:  PHP Request Startup: POST Content-Length of '
          '57400517 bytes exceeds the limit of 13631488 bytes in <b>Unknown</b> '
          'on line <b>0</b><br />\n',
          contentType: 'text/html; charset=UTF-8',
        );

        await expectRejected(
          adapter,
          await fileOfSize(1024),
          message:
              'The server did not accept this upload. Check that the file is '
              '10 MB or smaller, then try again.',
          statusCode: 200,
        );
      },
    );

    test('a 200 JSON body without an attachment is reported too', () async {
      final adapter = _FakeAdapter(200, jsonEncode({'success': true}));

      await expectRejected(
        adapter,
        await fileOfSize(1024),
        message:
            'The server did not accept this upload. Check that the file is '
            '10 MB or smaller, then try again.',
        statusCode: 200,
      );
    });

    test(
      'the backend 413 for an oversized body shows its own message',
      () async {
        final adapter = _FakeAdapter(
          413,
          jsonEncode({
            'success': false,
            'message':
                'The file is too large. Uploads must be 10 MB or smaller.',
            'data': null,
            'errors': null,
          }),
        );

        await expectRejected(
          adapter,
          await fileOfSize(1024),
          message: 'The file is too large. Uploads must be 10 MB or smaller.',
          statusCode: 413,
        );
      },
    );

    test(
      'a 422 validation failure keeps its message and field errors',
      () async {
        final adapter = _FakeAdapter(
          422,
          jsonEncode({
            'success': false,
            'message':
                'The file field must not be greater than 10240 kilobytes.',
            'data': null,
            'errors': {
              'file': [
                'The file field must not be greater than 10240 kilobytes.',
              ],
            },
          }),
        );

        await expectLater(
          repositoryWith(adapter).uploadAttachment(
            entityPathPrefix: 'debts/01DEBT',
            filePath: await fileOfSize(1024),
            fileName: 'receipt.pdf',
          ),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 422)
                .having((e) => e.fieldErrors?.keys, 'fields', ['file']),
          ),
        );
      },
    );

    test(
      'a missing local file still reports the generic upload failure',
      () async {
        final adapter = _FakeAdapter(201, jsonEncode(_created));

        await expectRejected(
          adapter,
          '${tempDir.path}/gone.pdf',
          message: 'Could not upload the file. Please try again.',
        );

        expect(adapter.requests, isEmpty);
      },
    );
  });
}
