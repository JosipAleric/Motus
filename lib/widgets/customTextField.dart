import 'package:flutter/material.dart';
import 'package:iconify_design/iconify_design.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String icon;
  final String hint;
  final TextInputType keyboardType;
  final String? suffixText;
  final String? Function(String?)? validator;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.suffixText,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconifyIcon(
                icon: icon,
                color: const Color(0xFF4E4E4E),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4E4E4E),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              suffixIcon: suffixText != null && suffixText!.isNotEmpty
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    suffixText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              )
                  : null,
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
              contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(
                  color: Color(0xFFEDEDED),
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(
                  color: Color(0xFFCCCCCC),
                  width: 1.0,
                ),
              ),
            ),
            keyboardType: keyboardType,
            validator: validator,
          ),
        ],
      ),
    );
  }
}
