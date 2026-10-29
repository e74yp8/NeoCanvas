import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _baseUrlController;
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscureToken = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: ref.read(baseUrlProvider));
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(
            baseUrl: _baseUrlController.text,
            token: _tokenController.text,
          );
    } on AppException catch (error) {
      if (mounted) {
        setState(() => _error = error.userMessage);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = '登入失敗：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'N',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(kAppName, style: theme.textTheme.titleLarge),
                            Text(
                              '給 CityU Canvas 的輕量用戶端',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text('Canvas 網域', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _baseUrlController,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: kDefaultBaseUrl,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '請輸入 Canvas 網域。';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Personal Access Token',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tokenController,
                      obscureText: _obscureToken,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: '貼上 token',
                        suffixIcon: IconButton(
                          tooltip: _obscureToken ? '顯示 token' : '隱藏 token',
                          onPressed: () =>
                              setState(() => _obscureToken = !_obscureToken),
                          icon: Icon(
                            _obscureToken
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '請輸入 Personal Access Token。';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    _TokenHelp(theme: theme),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('登入'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'token 僅儲存在本機安全儲存，不會上傳到其他伺服器。',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TokenHelp extends StatelessWidget {
  const _TokenHelp({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 4, bottom: 8),
        title: Text(
          '如何取得 token？',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        children: [
          _helpStep(theme, '1', '以瀏覽器登入 Canvas 網頁版。'),
          _helpStep(theme, '2', '點右上角 Account → Settings。'),
          _helpStep(theme, '3', '找到 Approved Integrations。'),
          _helpStep(theme, '4', '點 + New Access Token，產生後立即複製。'),
        ],
      ),
    );
  }

  Widget _helpStep(ThemeData theme, String index, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Text(
              index,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
