import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/document_actions.dart';
import '../providers/document_detail_providers.dart';

/// Every document this screen renders is a portrait, DomPDF-generated
/// page (Invoice/Receipt/Demand Letter/Statement — confirmed by reading
/// every Document Resource), always narrower-than-tall relative to this
/// screen's own preview viewport. `PhotoViewComputedScale.contained` —
/// the same baseline `pdfx` already uses by default — therefore always
/// resolves to a width-bound fit for this app's real document set, so it
/// doubles as an explicit "Fit Width" default without a bespoke scale
/// calculation. `minScale` pins that as the floor so pinch-to-zoom (via
/// `pdfx`'s built-in `PhotoView` gallery) only ever zooms in from there.
final _fitWidthBuilders = PdfViewBuilders<DefaultBuilderOptions>(
  options: const DefaultBuilderOptions(),
  pageBuilder: (context, pageImage, index, document) => PhotoViewGalleryPageOptions(
    imageProvider: PdfPageImageProvider(pageImage, index, document.id),
    minScale: PhotoViewComputedScale.contained,
    initialScale: PhotoViewComputedScale.contained,
    maxScale: PhotoViewComputedScale.contained * 4.0,
    heroAttributes: PhotoViewHeroAttributes(tag: '${document.id}-$index'),
  ),
);

/// Preview (§8.6) — a full-screen document viewer with Download (§8.7)
/// and Share (§8.8) actions in the header, matching the approved layout
/// exactly. There is no separate lightweight "preview content" endpoint
/// on the backend (confirmed by a full read of `DocumentController`) —
/// `GET /documents/{id}/download` is the only source of actual bytes,
/// and the backend itself records a `downloaded` `DocumentEvent` every
/// time it's called. The bytes are fetched exactly once per screen visit
/// and reused for both the in-app viewer and the explicit Download
/// action, so tapping Download doesn't trigger a second, redundant
/// server-side download record for the same visit.
///
/// Uses `pdfx` (PDFium-based) rather than `printing` — `printing` is
/// built for generating/printing PDFs and pulls in unused transitive
/// dependencies (image, archive, barcode, qr) for that purpose; `pdfx`
/// is a viewer-only package matching this screen's actual need (render
/// bytes that already exist), and this capability is not reused anywhere
/// else in the approved UI board.
class DocumentPreviewScreen extends ConsumerStatefulWidget {
  final String documentId;

  const DocumentPreviewScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends ConsumerState<DocumentPreviewScreen> {
  Future<Uint8List>? _bytesFuture;
  PdfController? _pdfController;
  String? _pdfError;

  Future<Uint8List> _loadBytes() async {
    final bytes = await ref.read(documentActionsProvider).fetchBytes(widget.documentId);
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List> _ensureBytes() => _bytesFuture ??= _loadBytes();

  void _ensurePdfController() {
    if (_pdfController != null || _pdfError != null) return;
    _pdfController = PdfController(
      document: _ensureBytes().then(
        PdfDocument.openData,
        onError: (Object error, StackTrace stackTrace) {
          setState(() => _pdfError = error.toString());
          throw error;
        },
      ),
    );
  }

  Future<void> _download(String referenceNumber) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _ensureBytes();
      final path = await ref.read(documentActionsProvider).saveToDevice(
            referenceNumber: referenceNumber,
            bytes: bytes,
          );
      messenger.showSnackBar(SnackBar(content: Text('Saved to $path')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documentAsync = ref.watch(documentDetailProvider(widget.documentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(documentAsync.valueOrNull != null
            ? '${documentAsync.valueOrNull!.referenceNumber}.pdf'
            : 'Document'),
        actions: documentAsync.valueOrNull == null
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.download_outlined),
                  tooltip: 'Download',
                  onPressed: () => _download(documentAsync.valueOrNull!.referenceNumber),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Share',
                  onPressed: () => context.push('/documents/${widget.documentId}/share'),
                ),
              ],
      ),
      body: documentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: RetrySection(
              message: 'Could not load this document.',
              onRetry: () => ref.invalidate(documentDetailProvider(widget.documentId)),
            ),
          ),
        ),
        data: (document) {
          _ensurePdfController();

          // The type icon/label row was dropped so the PDF itself gets
          // the full body — the rendered page already opens with its own
          // type + reference heading (e.g. "Receipt RCT-000003").
          return _pdfError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: RetrySection(
                      message: 'Could not render this document.',
                      onRetry: () => setState(() {
                        _pdfError = null;
                        _bytesFuture = null;
                        _pdfController = null;
                      }),
                    ),
                  ),
                )
              : PdfView(controller: _pdfController!, builders: _fitWidthBuilders);
        },
      ),
    );
  }
}
