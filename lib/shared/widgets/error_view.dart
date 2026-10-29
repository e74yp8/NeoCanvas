import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.error,
    this.onRetry,
    this.compact = false,
    super.key,
  });

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = error is AppException
        ? (error as AppException).userMessage
        : '發生未知錯誤，請稍後再試。';

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: compact ? 28 : 40,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重試'),
          ),
        ],
      ],
    );

    if (compact) {
      return Padding(padding: const EdgeInsets.all(24), child: content);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(padding: const EdgeInsets.all(32), child: content),
      ),
    );
  }
}
