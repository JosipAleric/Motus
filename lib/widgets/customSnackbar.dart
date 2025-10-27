import 'package:flutter/material.dart';

import 'customAlert.dart';

class CustomSnackbar extends StatefulWidget {
  final AlertType type;
  final String title;
  final String message;
  final Duration duration;
  final VoidCallback? onDismissed;

  const CustomSnackbar({
    Key? key,
    required this.type,
    required this.title,
    required this.message,
    this.duration = const Duration(seconds: 3),
    this.onDismissed,
  }) : super(key: key);

  @override
  State<CustomSnackbar> createState() => _CustomSnackbarState();

  /// Static helper za jednostavno prikazivanje preko Overlaya
  static void show(
      BuildContext context, {
        required AlertType type,
        required String title,
        required String message,
        Duration duration = const Duration(seconds: 3),
      }) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20,
        right: 20,
        child: SafeArea(
          child: CustomSnackbar(
            type: type,
            title: title,
            message: message,
            duration: duration,
            onDismissed: () => entry.remove(),
          ),
        ),
      ),
    );

    overlay.insert(entry);
  }
}

class _CustomSnackbarState extends State<CustomSnackbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    Future.delayed(widget.duration, () async {
      await _controller.reverse();
      if (mounted) widget.onDismissed?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0, right: 1.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _opacity,
              child: Material(
                color: Colors.transparent,
                child: CustomAlert(
                  type: widget.type,
                  title: widget.title,
                  message: widget.message,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
