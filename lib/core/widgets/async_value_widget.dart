import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders an [AsyncValue] with consistent loading/error/empty handling.
///
/// This replaces the hand-rolled
/// `FutureBuilder` + `connectionState` + `hasError` + empty-check block
/// that used to be copy-pasted into roughly fifteen screens, each with
/// slightly different spacing and error copy.
class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final String? errorContext;
  final Widget? loading;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.errorContext,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading ?? const _Padded(child: CircularProgressIndicator()),
      error: (error, _) => _Padded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(
              errorContext == null ? 'Something went wrong.' : 'Could not load $errorContext.',
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text('$error', style: const TextStyle(color: Colors.black54, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Convenience for the very common "async list that might be empty" case.
class AsyncListWidget<T> extends StatelessWidget {
  final AsyncValue<List<T>> value;
  final Widget Function(List<T> items) data;
  final String emptyMessage;
  final String? errorContext;

  const AsyncListWidget({
    super.key,
    required this.value,
    required this.data,
    required this.emptyMessage,
    this.errorContext,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncValueWidget<List<T>>(
      value: value,
      errorContext: errorContext,
      data: (items) => items.isEmpty ? EmptyState(message: emptyMessage) : data(items),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return _Padded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: Colors.black26),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Padded extends StatelessWidget {
  final Widget child;

  const _Padded({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Center(child: child),
    );
  }
}
