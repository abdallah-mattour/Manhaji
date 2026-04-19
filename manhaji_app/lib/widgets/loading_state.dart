import 'package:flutter/material.dart';

/// A centered circular progress indicator used while data is being fetched.
///
/// Trivial wrapper, but standardizes the pattern so screens don't hand-roll
/// `Center(child: CircularProgressIndicator())` inline.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
