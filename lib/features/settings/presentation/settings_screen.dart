import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../files/data/pdf_cache_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final baseUrl = ref.watch(baseUrlProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;

    return AppScaffold(
      currentIndex: 1,
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _SectionTitle('帳號'),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                user == null || user.displayName.isEmpty
                    ? '?'
                    : user.displayName.substring(0, 1).toUpperCase(),
              ),
            ),
            title: Text(user?.displayName ?? '未登入'),
            subtitle: Text(user?.primaryEmail ?? baseUrl),
          ),
          const Divider(),
          const _SectionTitle('外觀'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('亮色'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('暗色'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('跟隨系統'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) =>
                  ref.read(themeModeProvider.notifier).setMode(selection.first),
            ),
          ),
          const Divider(),
          const _SectionTitle('Canvas'),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('伺服器'),
            subtitle: Text(baseUrl),
          ),
          const ListTile(
            leading: Icon(Icons.password_outlined),
            title: Text('認證方式'),
            subtitle: Text('Personal Access Token（儲存在本機安全儲存）'),
          ),
          const Divider(),
          const _SectionTitle('儲存'),
          const _CacheInfo(),
          const Divider(),
          const _SectionTitle('關於'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(kAppName),
            subtitle: Text('MVP · 0.1.0'),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              '登出',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('確定登出？'),
        content: const Text('本機 token 與 PDF 快取將會被清除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('登出'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(pdfCacheServiceProvider).clear();
    await ref.read(authControllerProvider.notifier).signOut();
  }
}

class _CacheInfo extends ConsumerStatefulWidget {
  const _CacheInfo();

  @override
  ConsumerState<_CacheInfo> createState() => _CacheInfoState();
}

class _CacheInfoState extends ConsumerState<_CacheInfo> {
  int? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await ref.read(pdfCacheServiceProvider).totalBytes();
    if (mounted) {
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清除 PDF 快取？'),
        content: const Text('下次開啟 PDF 時會重新下載。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(pdfCacheServiceProvider).clear();
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf_outlined),
      title: const Text('PDF 快取'),
      subtitle: Text(_loading ? '計算中…' : _formatBytes(_bytes ?? 0)),
      trailing: TextButton(
        onPressed: _loading ? null : _clear,
        child: const Text('清除'),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
