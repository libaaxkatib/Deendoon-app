import 'package:flutter/material.dart';

import '../../../../core/widgets/bottom_sheet_content.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../customers/domain/customer_phone_number.dart';

/// Fix #23 Decision 8 — shown before a manual Call/WhatsApp/SMS action
/// whenever the customer has more than one phone number. When there's
/// only one (the common case), it's returned immediately with no sheet
/// shown at all, so single-number customers see no change in behavior.
/// Returns `null` only if the user dismisses the sheet without choosing
/// — the caller's existing "no phone number" handling covers the
/// zero-numbers case separately.
Future<CustomerPhoneNumber?> pickPhoneNumber(
  BuildContext context,
  List<CustomerPhoneNumber> phoneNumbers,
) async {
  if (phoneNumbers.isEmpty) return null;
  if (phoneNumbers.length == 1) return phoneNumbers.first;

  return showModalBottomSheet<CustomerPhoneNumber>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PhoneNumberPickerSheet(phoneNumbers: phoneNumbers),
  );
}

class _PhoneNumberPickerSheet extends StatefulWidget {
  final List<CustomerPhoneNumber> phoneNumbers;

  const _PhoneNumberPickerSheet({required this.phoneNumbers});

  @override
  State<_PhoneNumberPickerSheet> createState() =>
      _PhoneNumberPickerSheetState();
}

class _PhoneNumberPickerSheetState extends State<_PhoneNumberPickerSheet> {
  late CustomerPhoneNumber _selected = widget.phoneNumbers.firstWhere(
    (p) => p.isPrimary,
    orElse: () => widget.phoneNumbers.first,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BottomSheetContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.phoneNumberPickerTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          RadioGroup<CustomerPhoneNumber>(
            groupValue: _selected,
            onChanged: (value) => setState(() => _selected = value ?? _selected),
            child: Column(
              children: [
                for (final phone in widget.phoneNumbers)
                  RadioListTile<CustomerPhoneNumber>(
                    contentPadding: EdgeInsets.zero,
                    value: phone,
                    title: Text(phone.phone),
                    subtitle: phone.isPrimary
                        ? Text(l10n.addEditCustomerPhonePrimaryBadge)
                        : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            child: Text(l10n.phoneNumberPickerContinueButton),
          ),
        ],
      ),
    );
  }
}
