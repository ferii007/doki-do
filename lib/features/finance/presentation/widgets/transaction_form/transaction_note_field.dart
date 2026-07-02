import 'package:flutter/material.dart';

class TransactionNoteField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const TransactionNoteField({
    super.key,
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
