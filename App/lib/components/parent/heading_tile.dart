import 'package:flutter/material.dart';

class HeadingTile extends StatelessWidget {
  const HeadingTile(this.data,
      {Key? key, this.leading, this.subtitle, this.trailing})
      : super(key: key);

  final String data;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
      leading: leading,
      title: Text(data,
          style: Theme.of(context)
              .textTheme
              .headlineMedium!
              .copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
      subtitle: subtitle,
      trailing: trailing);
}
