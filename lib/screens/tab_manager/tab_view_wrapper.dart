import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class TabViewWrapper extends StatelessWidget {
  final Widget child;

  const TabViewWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('es', 'CR'),
      delegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: Theme(
        data: Theme.of(context),
        child: Builder(
          builder: (context) {
            return child;
          },
        ),
      ),
    );
  }
}