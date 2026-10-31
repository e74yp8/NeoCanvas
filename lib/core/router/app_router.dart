import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/course_home/presentation/course_home_screen.dart';
import '../../features/courses/presentation/courses_shell.dart';
import '../../features/files/domain/course_file.dart';
import '../../features/files/presentation/files_screen.dart';
import '../../features/pdf_viewer/presentation/pdf_viewer_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, _) => refresh.refresh());

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isLogin = location == '/login';
      final isSplash = location == '/splash';

      return switch (auth) {
        AuthUnknown() => isSplash ? null : '/splash',
        AuthUnauthenticated() => isLogin ? null : '/login',
        AuthAuthenticated() => (isLogin || isSplash) ? '/courses' : null,
      };
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            CoursesShell(state: state, child: child),
        routes: [
          GoRoute(path: '/courses', builder: (_, _) => const SizedBox.shrink()),
          GoRoute(
            path: '/courses/:courseId',
            builder: (_, state) => CourseHomePane(
              courseId:
                  int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/courses/:courseId/files',
        builder: (_, state) => FilesScreen(
          courseId: int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/courses/:courseId/files/:fileId',
        builder: (_, state) {
          final extra = state.extra;
          return PdfViewerScreen(
            courseId: int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0,
            fileId: int.tryParse(state.pathParameters['fileId'] ?? '') ?? 0,
            initialFile: extra is CourseFile ? extra : null,
          );
        },
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}
