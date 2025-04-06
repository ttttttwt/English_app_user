import 'package:flutter/material.dart';

/// Navigates to a new page with a sliding animation.
///
/// [context] The build context.
/// [page] The destination page widget.
/// [clearStack] If true, clears the entire navigation stack.
/// [begin] Starting position for slide animation, defaults to right-to-left.
/// [duration] Duration of the animation, defaults to 300ms.
/// [curve] Animation curve to use, defaults to ease.
Future<T?> navigateWithSlide<T>(
  BuildContext context,
  Widget page, {
  bool clearStack = false,
  Offset begin = const Offset(1.0, 0.0),
  Duration duration = const Duration(milliseconds: 300),
  Curve curve = Curves.ease,
}) {
  final PageRouteBuilder<T> pageRoute = PageRouteBuilder<T>(
    transitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween =
          Tween(begin: begin, end: Offset.zero).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );

  if (clearStack) {
    return Navigator.pushAndRemoveUntil(
      context,
      pageRoute,
      (route) => false,
    );
  }
  return Navigator.push(context, pageRoute);
}
