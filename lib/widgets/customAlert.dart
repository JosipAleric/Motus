import 'package:flutter/material.dart';
import 'package:iconify_design/iconify_design.dart';

enum AlertType { success, error, warning, info }

class CustomAlert extends StatelessWidget {
  final AlertType type;
  final String title;
  final String message;

  const CustomAlert({
    Key? key,
    required this.type,
    required this.title,
    required this.message,
  }) : super(key: key);

  Color _getBackgroundColor(BuildContext context) {
    switch (type) {
      case AlertType.success:
        return Color(0xFFe5faf4);
      case AlertType.error:
        return Color(0xFFfeefee);
      case AlertType.warning:
        return Color(0xFFfff8e9);
      case AlertType.info:
        return Color(0xFFe4f2fd);
    }
  }

  Color _getIconColor(BuildContext context) {
    switch (type) {
      case AlertType.success:
        return Color(0xFF01cc99);
      case AlertType.error:
        return Color(0xFFeb5656);
      case AlertType.warning:
        return Color(0xFFf2c84d);
      case AlertType.info:
        return Color(0xFF2196f3);
    }
  }

  String _getIconData() {
    switch (type) {
      case AlertType.success:
        //return "solar:check-read-broken";
        return "solar:info-square-broken";
      case AlertType.error:
        return "solar:folder-error-broken";
      case AlertType.warning:
        return "solar:shield-warning-broken";
      case AlertType.info:
        return "solar:info-square-broken";
    }
  }

  Widget _buildIcon(BuildContext context) {
    final iconColor = _getIconColor(context);

    return Center(
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: iconColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: iconColor,
            width: 2.0,
          ),
        ),
        child: Center(
          child: IconifyIcon(
            icon: _getIconData(),
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
    );
  }

  Widget _buildLeftBorder(BuildContext context) {
    final iconColor = _getIconColor(context);
    return Container(
      width: 4.0,
      decoration: BoxDecoration(
        color: iconColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          bottomLeft: Radius.circular(8.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildLeftBorder(context),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildIcon(context),
                    const SizedBox(width: 20.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.0,
                              color: Colors.black87,
                              letterSpacing: 0.5
                            ),
                          ),
                          const SizedBox(height: 5.0),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 11.0,
                              color: Color(0xFF575757),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconifyIcon(icon: "material-symbols:close-rounded", size: 16, color: Colors.black54)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}