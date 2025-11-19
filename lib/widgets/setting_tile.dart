import 'package:flutter/material.dart';

class SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool value;
  final Function(bool)? onChanged;
  final bool enabled;

  const SettingTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: enabled ? iconColor : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: enabled ? Colors.black : Colors.grey,
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: Colors.green,
    );
  }
}