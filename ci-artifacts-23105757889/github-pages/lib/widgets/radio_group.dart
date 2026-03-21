import 'package:flutter/material.dart';

class AppRadioOption<T> {
  final T value;
  final Widget title;
  final Widget? trailing;

  AppRadioOption({required this.value, required this.title, this.trailing});
}

class AppRadioGroup<T> extends StatelessWidget {
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final List<AppRadioOption<T>> options;
  final Axis axis;

  const AppRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.options,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.horizontal) {
      return Row(
        children: options.map((opt) {
          return Expanded(
            child: InkWell(
              onTap: () => onChanged?.call(opt.value),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                child: Row(
                  children: [
                    // ignore: deprecated_member_use
                    Radio<T>(value: opt.value, groupValue: groupValue, onChanged: onChanged),
                    const SizedBox(width: 6),
                    Expanded(child: opt.title),
                    if (opt.trailing != null) const SizedBox(width: 8),
                    if (opt.trailing != null) opt.trailing!,
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: options.map((opt) {
        return ListTile(
          onTap: () => onChanged?.call(opt.value),
          // ignore: deprecated_member_use
          leading: Radio<T>(value: opt.value, groupValue: groupValue, onChanged: onChanged),
          title: opt.title,
          trailing: opt.trailing,
        );
      }).toList(),
    );
  }
}
