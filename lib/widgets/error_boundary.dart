import 'package:flutter/material.dart';

typedef SafeBuilder = Widget Function(BuildContext context);

class ErrorBoundary extends StatefulWidget {
  final SafeBuilder builder;
  final Widget? fallback;
  const ErrorBoundary({Key? key, required this.builder, this.fallback}) : super(key: key);

  @override
  _ErrorBoundaryState createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback ??
          Center(child: Text('Une erreur est survenue: $_error'));
    }
    try {
      return widget.builder(context);
    } catch (e) {
      _error = e;
      // rebuild to show fallback
      return widget.fallback ??
          Center(child: Text('Une erreur est survenue: $e'));
    }
  }
}
