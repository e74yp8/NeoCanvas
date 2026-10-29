import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_view.dart';
import '../../files/data/files_repository.dart';
import '../../files/data/pdf_cache_service.dart';
import '../../files/domain/course_file.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({
    required this.courseId,
    required this.fileId,
    this.initialFile,
    super.key,
  });

  final int courseId;
  final int fileId;
  final CourseFile? initialFile;

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();

  CourseFile? _file;
  File? _localFile;
  String? _error;
  bool _loading = true;
  double? _progress;
  int _pageNumber = 1;
  int _pageCount = 0;
  int _initialPage = 1;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    unawaited(_persistPage(_pageNumber));
    super.dispose();
  }

  Future<void> _prepare() async {
    setState(() {
      _loading = true;
      _error = null;
      _progress = null;
    });

    try {
      final file =
          widget.initialFile ??
          await ref
              .read(filesRepositoryProvider)
              .getFile(widget.fileId, courseId: widget.courseId);
      if (!file.isPdf) {
        throw const DownloadException('此檔案不是 PDF。');
      }

      final saved = ref
          .read(sharedPreferencesProvider)
          .getInt('$kPdfLastPagePrefsKey:${file.id}');
      final localFile = await ref
          .read(pdfCacheServiceProvider)
          .ensureDownloaded(
            file,
            onProgress: (received, total) {
              if (mounted) {
                setState(() {
                  _progress = total > 0 ? received / total : null;
                });
              }
            },
          );

      if (!mounted) {
        return;
      }
      setState(() {
        _file = file;
        _localFile = localFile;
        _initialPage = saved ?? 1;
        _pageNumber = saved ?? 1;
        _loading = false;
      });
    } on AppException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.userMessage;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '無法開啟 PDF：$error';
          _loading = false;
        });
      }
    }
  }

  void _onPageChanged(int? page) {
    if (page == null) {
      return;
    }
    setState(() => _pageNumber = page);
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 600),
      () => unawaited(_persistPage(page)),
    );
  }

  Future<void> _persistPage(int page) async {
    final file = _file;
    if (file == null) {
      return;
    }
    await ref
        .read(sharedPreferencesProvider)
        .setInt('$kPdfLastPagePrefsKey:${file.id}', page);
  }

  Future<void> _goToPage(int page) async {
    if (page < 1 || (_pageCount > 0 && page > _pageCount)) {
      return;
    }
    await _controller.goToPage(pageNumber: page);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = _file;
    final title = file?.displayName ?? 'PDF';

    return AppScaffold(
      showNavigation: false,
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (_pageCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$_pageNumber / $_pageCount',
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(theme),
      floatingActionButton: _localFile == null || _pageCount <= 1
          ? null
          : FloatingActionButton.small(
              tooltip: '下一頁',
              onPressed: _pageNumber < _pageCount
                  ? () => _goToPage(_pageNumber + 1)
                  : null,
              child: const Icon(Icons.chevron_right),
            ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  _file?.displayName ?? '準備 PDF…',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 8),
                Text(
                  _progress == null ? '下載中…' : '${(_progress! * 100).round()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return ErrorView(error: _error!, onRetry: _prepare);
    }

    final localFile = _localFile;
    if (localFile == null) {
      return ErrorView(error: '找不到本機 PDF。', onRetry: _prepare);
    }

    return Column(
      children: [
        Expanded(
          child: PdfViewer.file(
            localFile.path,
            controller: _controller,
            initialPageNumber: _initialPage,
            params: PdfViewerParams(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              margin: 8,
              pageDropShadow: const BoxShadow(
                color: Color(0x22000000),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
              onDocumentChanged: (document) {
                if (document != null && mounted) {
                  setState(() => _pageCount = document.pages.length);
                }
              },
              onPageChanged: _onPageChanged,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: '上一頁',
                onPressed: _pageNumber > 1
                    ? () => _goToPage(_pageNumber - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                _pageCount > 0 ? '$_pageNumber / $_pageCount' : '$_pageNumber',
                style: theme.textTheme.labelMedium,
              ),
              IconButton(
                tooltip: '下一頁',
                onPressed: _pageCount > 0 && _pageNumber < _pageCount
                    ? () => _goToPage(_pageNumber + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
              const Spacer(),
              Text(
                'Ctrl+滾輪縮放 · 雙指縮放',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
