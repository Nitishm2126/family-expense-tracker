import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_provider.dart';
import '../../core/widgets/app_footer.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);


    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const _SectionHeader(title: 'Preferences'),
          _SettingsTile(
            icon: Icons.currency_rupee_rounded,
            title: 'Currency',
            trailing: Text(settings.currency, style: AppTextStyles.bodyMedium(AppColors.primary)),
            onTap: () => _showCurrencyPicker(context, settings.currency, controller.setCurrency),
          ),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Theme',
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              ],
              onChanged: (v) {
                if (v != null) controller.setThemeMode(v);
              },
            ),
          ),
          _SettingsTile(
            icon: Icons.notifications_active_outlined,
            title: 'Expense Reminder',
            trailing: Switch(
              value: settings.reminderEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: controller.setReminderEnabled,
            ),
          ),
          _SettingsTile(
            icon: Icons.warning_amber_rounded,
            title: 'Budget Alert Threshold',
            trailing: Text('${(settings.budgetAlertThreshold * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.bodyMedium(AppColors.warning)),
            onTap: () => _showThresholdPicker(context, settings.budgetAlertThreshold, controller.setBudgetAlertThreshold),
          ),
          const SizedBox(height: 8),
          const _SectionHeader(title: 'Navigation Bar Appearance'),
          _SettingsTile(
            icon: Icons.opacity_rounded,
            title: 'Glass Transparency',
            subtitle: '${(settings.glassTransparency * 100).toStringAsFixed(0)}%',
            onTap: () => _showSliderPicker(
              context,
              'Glass Transparency',
              settings.glassTransparency,
              0.0,
              1.0,
              100,
              controller.setGlassTransparency,
            ),
          ),
          _SettingsTile(
            icon: Icons.blur_on_rounded,
            title: 'Glass Blur',
            subtitle: settings.glassBlur.toStringAsFixed(0),
            onTap: () => _showSliderPicker(
              context,
              'Glass Blur',
              settings.glassBlur,
              0.0,
              30.0,
              30,
              controller.setGlassBlur,
            ),
          ),
          _SettingsTile(
            icon: Icons.border_outer_rounded,
            title: 'Glass Border',
            trailing: Switch(
              value: settings.glassBorderEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: controller.setGlassBorderEnabled,
            ),
          ),
          _SettingsTile(
            icon: Icons.layers_rounded,
            title: 'Glass Shadow',
            trailing: Switch(
              value: settings.glassShadowEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: controller.setGlassShadowEnabled,
            ),
          ),
          const SizedBox(height: 8),
          const _SectionHeader(title: 'Data'),
          _SettingsTile(
            icon: Icons.backup_outlined,
            title: 'Backup & Restore',
            subtitle: 'Your data is securely backed up to Supabase',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.download_outlined,
            title: 'Export Data',
            subtitle: 'Download all records as PDF',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          const _SectionHeader(title: 'Security'),
          _SettingsTile(
            icon: Icons.lock_reset_rounded,
            title: 'Change Password',
            onTap: () => _showChangePasswordSheet(context, ref),
          ),
          const SizedBox(height: 8),
          const _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About App',
            subtitle: '${AppConstants.appName} · v1.0.0',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Logout',
                  message: 'You will need the family password to log back in.',
                  confirmLabel: 'Logout',
                );
                if (confirmed) {
                  await ref.read(authControllerProvider.notifier).logout();
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ),
          const SizedBox(height: 12),
          const AppFooter(),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, String current, ValueChanged<String> onSelected) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.currencies
              .map((c) => ListTile(
                    title: Text(c),
                    trailing: c == current ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                    onTap: () {
                      onSelected(c);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showThresholdPicker(BuildContext context, double current, ValueChanged<double> onSelected) {
    double value = current;
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Alert when spending reaches ${(value * 100).toStringAsFixed(0)}% of budget'),
              Slider(
                value: value,
                min: 0.5,
                max: 1.0,
                divisions: 10,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => value = v),
              ),
              PrimaryButton(
                label: 'Save',
                onPressed: () {
                  onSelected(value);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSliderPicker(BuildContext context, String title, double current, double min, double max, int divisions, ValueChanged<double> onSelected) {
    double value = current;
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Text(title, style: AppTextStyles.title(Theme.of(context).colorScheme.onSurface)),
               const SizedBox(height: 16),
               Slider(
                 value: value,
                 min: min,
                 max: max,
                 divisions: divisions,
                 activeColor: AppColors.primary,
                 onChanged: (v) {
                   setState(() => value = v);
                   onSelected(v);
                 },
               ),
               PrimaryButton(
                 label: 'Close',
                 onPressed: () => Navigator.pop(context),
               ),
             ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  bool _isSaving = false;

  Future<void> _submit() async {
    if (_oldController.text.isEmpty || _newController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 4 characters')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final ok = await ref
        .read(authServiceProvider)
        .changePassword(_oldController.text, _newController.text);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Password changed successfully' : 'Current password is incorrect')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Change Password', style: AppTextStyles.title(Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16),
          TextField(
            controller: _oldController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Current password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'New password'),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Update Password', isLoading: _isSaving, onPressed: _submit),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.captionMedium(AppColors.primary).copyWith(letterSpacing: 0.6),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: AppTextStyles.bodyMedium(theme.colorScheme.onSurface)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.caption(theme.colorScheme.onSurface.withValues(alpha: 0.55)))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
    );
  }
}
// ignore_for_file: deprecated_member_use, unused_local_variable

