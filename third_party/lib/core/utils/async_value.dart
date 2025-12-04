/// Represents the state of an asynchronous operation
/// Used in ViewModels to handle loading, data, and error states
sealed class AsyncValue<T> {
  const AsyncValue();
}

/// Loading state - operation in progress
class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}

/// Data state - operation completed successfully
class AsyncData<T> extends AsyncValue<T> {
  const AsyncData(this.data);
  final T data;
}

/// Error state - operation failed
class AsyncError<T> extends AsyncValue<T> {
  const AsyncError(this.message, [this.error, this.stackTrace]);
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
}

/// Extension methods for AsyncValue
extension AsyncValueX<T> on AsyncValue<T> {
  /// Check if in loading state
  bool get isLoading => this is AsyncLoading<T>;

  /// Check if has data
  bool get hasData => this is AsyncData<T>;

  /// Check if has error
  bool get hasError => this is AsyncError<T>;

  /// Get data or null
  T? get dataOrNull => this is AsyncData<T> ? (this as AsyncData<T>).data : null;

  /// Get error message or null
  String? get errorOrNull => this is AsyncError<T> ? (this as AsyncError<T>).message : null;

  /// Map the value when it's data
  AsyncValue<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      AsyncLoading() => const AsyncLoading(),
      AsyncData(:final data) => AsyncData(transform(data)),
      AsyncError(:final message, :final error, :final stackTrace) => 
        AsyncError(message, error, stackTrace),
    };
  }

  /// Execute different callbacks based on state
  R when<R>({
    required R Function() loading,
    required R Function(T data) data,
    required R Function(String message) error,
  }) {
    return switch (this) {
      AsyncLoading() => loading(),
      AsyncData(data: final value) => data(value),
      AsyncError(:final message) => error(message),
    };
  }
}