import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../models/ethos_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ethos_provider.dart';

/// Modal bottom sheet untuk mengedit isi kata-kata "The Writelle Ethos" langsung dari dalam aplikasi.
class WrittleEditEthosSheet extends ConsumerStatefulWidget {
  const WrittleEditEthosSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WrittleEditEthosSheet(),
    );
  }

  @override
  ConsumerState<WrittleEditEthosSheet> createState() => _WrittleEditEthosSheetState();
}

class _WrittleEditEthosSheetState extends ConsumerState<WrittleEditEthosSheet> {
  late final TextEditingController _headerController;
  late final TextEditingController _quoteController;
  late final TextEditingController _subtextController;
  late final TextEditingController _buttonLabelController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(ethosProvider);
    _headerController = TextEditingController(text: current.header);
    _quoteController = TextEditingController(text: current.quote);
    _subtextController = TextEditingController(text: current.subtext);
    _buttonLabelController = TextEditingController(text: current.buttonLabel);
  }

  @override
  void dispose() {
    _headerController.dispose();
    _quoteController.dispose();
    _subtextController.dispose();
    _buttonLabelController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final profile = ref.read(currentUserProfileProvider).value;
    if (profile != null && profile.role != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Only administrators have authority to edit The Writelle Ethos.'),
        ),
      );
      return;
    }

    final header = _headerController.text.trim();
    final quote = _quoteController.text.trim();
    final subtext = _subtextController.text.trim();
    final buttonLabel = _buttonLabelController.text.trim();

    if (quote.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Philosophy quote cannot be empty.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updatedEthos = EthosModel(
      header: header.isNotEmpty ? header : 'THE WRITELLE ETHOS',
      quote: quote,
      subtext: subtext.isNotEmpty ? subtext : 'A sanctuary of true expressions',
      buttonLabel: buttonLabel.isNotEmpty ? buttonLabel : 'Pen a Tale',
    );

    await ref.read(ethosProvider.notifier).updateEthos(updatedEthos);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.burntSienna,
          content: Text('The Writelle Ethos has been updated.'),
        ),
      );
    }
  }

  Future<void> _handleReset() async {
    final profile = ref.read(currentUserProfileProvider).value;
    if (profile != null && profile.role != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Only administrators have authority to edit The Writelle Ethos.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Restore to Default?',
          style: AppTypography.storyHeading.copyWith(fontSize: 18),
        ),
        content: Text(
          'Text will be reverted to the default Writelle Ethos quote.',
          style: AppTypography.uiBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.burntSienna),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.read(ethosProvider.notifier).resetToDefault();
    final initial = EthosModel.initial();
    _headerController.text = initial.header;
    _quoteController.text = initial.quote;
    _subtextController.text = initial.subtext;
    _buttonLabelController.text = initial.buttonLabel;

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The Writelle Ethos has been reset to default.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: bottomInset > 0 ? bottomInset + 12 : 24,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.warmSand.withValues(alpha: isDark ? 0.2 : 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.warmSand.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.burntSienna.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_note, color: AppColors.burntSienna, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configure The Writelle Ethos',
                        style: AppTypography.storyHeading.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Customize homepage philosophy and editorial quote',
                        style: AppTypography.captionMeta.copyWith(
                          color: AppColors.textSecondaryColor(context),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Field 1: Tagline / Kicker
            _buildLabel('Tagline / Kicker'),
            const SizedBox(height: 6),
            TextField(
              controller: _headerController,
              textCapitalization: TextCapitalization.characters,
              decoration: _inputDecoration(
                context,
                hintText: 'e.g. THE WRITELLE ETHOS',
              ),
              style: AppTypography.uiBodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 14),

            // Field 2: Pesan Filosofi / Quote
            _buildLabel('Philosophy Quote / Creed'),
            const SizedBox(height: 6),
            TextField(
              controller: _quoteController,
              maxLines: 3,
              decoration: _inputDecoration(
                context,
                hintText: 'Write your philosophical reflection or creed here...',
              ),
              style: AppTypography.pullQuote.copyWith(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 14),

            // Field 3: Subtext / Keterangan Bawah
            _buildLabel('Supporting Subtext'),
            const SizedBox(height: 6),
            TextField(
              controller: _subtextController,
              decoration: _inputDecoration(
                context,
                hintText: 'e.g. A sanctuary of true expressions',
              ),
              style: AppTypography.uiBodyMedium,
            ),
            const SizedBox(height: 14),

            // Field 4: Label Tombol Tulis
            _buildLabel('Action Button Label'),
            const SizedBox(height: 6),
            TextField(
              controller: _buttonLabelController,
              decoration: _inputDecoration(
                context,
                hintText: 'e.g. Pen a Tale',
              ),
              style: AppTypography.uiBodyMedium,
            ),
            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : _handleReset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.mutedCocoa,
                    side: BorderSide(color: AppColors.warmSand.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reset', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.burntSienna,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: AppTypography.captionMeta.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryColor(context),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, {required String hintText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.captionMeta.copyWith(
        color: AppColors.textTertiaryColor(context),
      ),
      filled: true,
      fillColor: isDark
          ? AppColors.softParchment.withValues(alpha: 0.05)
          : AppColors.softParchment.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppColors.warmSand.withValues(alpha: isDark ? 0.3 : 0.6),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppColors.warmSand.withValues(alpha: isDark ? 0.3 : 0.6),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.burntSienna, width: 1.5),
      ),
    );
  }
}
