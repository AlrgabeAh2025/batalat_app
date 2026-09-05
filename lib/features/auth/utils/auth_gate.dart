/// Batalat — Require authentication before protected actions
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/features/auth/providers/auth_provider.dart';

/// Returns true if the user is signed in. Otherwise opens login with [returnTo].
bool requireAuth(
  BuildContext context,
  WidgetRef ref, {
  String? returnTo,
  String? message,
}) {
  if (ref.read(isAuthenticatedProvider)) return true;

  final target = returnTo ?? GoRouterState.of(context).uri.toString();
  final encoded = Uri.encodeComponent(target);
  context.push('${AppRoutes.login}?returnTo=$encoded');

  if (message != null && message.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  return false;
}

String? loginReturnTo(GoRouterState state) {
  final raw = state.uri.queryParameters['returnTo'];
  if (raw == null || raw.isEmpty) return null;
  if (!raw.startsWith('/')) return null;
  if (raw.startsWith('/login') || raw.startsWith('/register')) return null;
  return raw;
}

void navigateAfterAuth(BuildContext context, {String? returnTo}) {
  if (returnTo != null && returnTo.isNotEmpty) {
    context.go(returnTo);
  } else {
    context.go(AppRoutes.home);
  }
}
