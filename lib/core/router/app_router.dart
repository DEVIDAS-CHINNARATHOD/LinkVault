// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import '../../features/groups/presentation/pages/groups_screen.dart';
import '../../features/links/presentation/pages/add_edit_link_screen.dart';
import '../../features/links/presentation/pages/all_links_screen.dart';
import '../../features/links/presentation/pages/home_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/vault/presentation/pages/vault_lock_screen.dart';
import '../../features/vault/presentation/pages/vault_setup_screen.dart';
import '../../main_scaffold.dart';

/// Named route constants for the app.
class AppRoutes {
  static const home = '/';
  static const allLinks = '/links';
  static const addLink = '/links/add';
  static const groups = '/groups';
  static const vaultLock = '/vault';
  static const vaultSetup = '/vault/setup';
  static const settings = '/settings';
}

/// Route generator for MaterialApp.
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return _fade(const MainScaffold());

      case AppRoutes.allLinks:
        return _slide(const AllLinksScreen());

      case AppRoutes.addLink:
        return _slide(const AddEditLinkScreen());

      case AppRoutes.groups:
        return _slide(const GroupsScreen());

      case AppRoutes.vaultLock:
        return _fade(const VaultLockScreen());

      case AppRoutes.vaultSetup:
        return _slide(const VaultSetupScreen());

      case AppRoutes.settings:
        return _slide(const SettingsScreen());

      default:
        return _fade(const MainScaffold());
    }
  }

  static PageRouteBuilder _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  static PageRouteBuilder _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, secondaryAnim, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(
          position: anim.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}
