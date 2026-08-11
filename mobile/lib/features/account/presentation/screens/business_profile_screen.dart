import 'dart:io';

import 'package:dio/dio.dart' show MultipartFile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../data/business_profile_repository.dart';
import '../../domain/business_profile.dart';
import '../providers/business_profile_providers.dart';

/// Company Profile & Branding (FR-068) — real, wired to
/// `GET/PUT /admin/settings/company-profile` via `BusinessProfileRepository`.
/// Company Name/Address/Contact Email/Contact Phone are plain text fields;
/// the Logo is the one file-upload field in the whole backend, sent as
/// multipart (see `BusinessProfileApi.update`'s own doc comment for why
/// it's sent as `POST` + `_method=PUT` rather than a raw `PUT`).
class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  static const _allowedLogoExtensions = {'jpg', 'jpeg', 'png'};
  static const _maxLogoBytes = 2 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  bool _prefilled = false;
  bool _isSaving = false;
  String? _error;
  String? _successMessage;
  XFile? _pickedLogo;
  String? _logoError;

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  void _prefillFromExisting(BusinessProfile profile) {
    if (_prefilled) return;
    _prefilled = true;
    _businessNameController.text = profile.businessName;
    _addressController.text = profile.address ?? '';
    _contactEmailController.text = profile.contactEmail ?? '';
    _contactPhoneController.text = profile.contactPhone ?? '';
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final extension = file.name.split('.').last.toLowerCase();
    if (!_allowedLogoExtensions.contains(extension)) {
      setState(() => _logoError = 'Logo must be a JPEG or PNG image.');
      return;
    }

    final sizeBytes = await file.length();
    if (sizeBytes > _maxLogoBytes) {
      setState(() => _logoError = 'Logo must be 2MB or smaller.');
      return;
    }

    setState(() {
      _pickedLogo = file;
      _logoError = null;
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_logoError != null) return;

    setState(() {
      _isSaving = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final logo = _pickedLogo == null
          ? null
          : await MultipartFile.fromFile(_pickedLogo!.path, filename: _pickedLogo!.name);

      await ref.read(businessProfileRepositoryProvider).updateBusinessProfile(
            businessName: _businessNameController.text.trim(),
            address: _addressController.text.trim(),
            contactEmail: _contactEmailController.text.trim(),
            contactPhone: _contactPhoneController.text.trim(),
            logo: logo,
          );

      ref.invalidate(businessProfileProvider);
      if (!mounted) return;
      setState(() {
        _successMessage = 'Business Profile updated successfully';
        _pickedLogo = null;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(businessProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Business Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: RetrySection(
            message: 'Could not load your business profile.',
            onRetry: () => ref.invalidate(businessProfileProvider),
          ),
        ),
        data: (profile) {
          _prefillFromExisting(profile);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: _LogoPicker(
                      pickedLogo: _pickedLogo,
                      hasExistingLogo: profile.logoPath != null,
                      error: _logoError,
                      onTap: _pickLogo,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(labelText: 'Company Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Company name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Contact Email'),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) return null;
                      final validEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
                      return validEmail ? null : 'Enter a valid email address';
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Contact Phone'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Business Address'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  if (_successMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_successMessage!, style: const TextStyle(color: Colors.green)),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(label: 'Save Changes', isLoading: _isSaving, onPressed: _save),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The logo field. Only ever renders a real image preview for a file the
/// user just picked on this device (`Image.file`) — `profile.logoPath` is
/// a private-disk storage path, not a servable URL (no route exists to
/// fetch the stored logo's bytes), so an already-uploaded logo is
/// acknowledged with a neutral icon/label rather than a fabricated image.
class _LogoPicker extends StatelessWidget {
  final XFile? pickedLogo;
  final bool hasExistingLogo;
  final String? error;
  final VoidCallback onTap;

  const _LogoPicker({
    required this.pickedLogo,
    required this.hasExistingLogo,
    required this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 96,
            height: 96,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.colors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.textSecondary.withValues(alpha: 0.24)),
            ),
            child: pickedLogo != null
                ? Image.file(File(pickedLogo!.path), fit: BoxFit.cover)
                : Icon(
                    hasExistingLogo ? Icons.business_outlined : Icons.add_photo_alternate_outlined,
                    size: 36,
                    color: context.colors.textSecondary,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pickedLogo != null
              ? 'New logo selected'
              : (hasExistingLogo ? 'Logo on file — tap to replace' : 'Tap to add a logo'),
          style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }
}
