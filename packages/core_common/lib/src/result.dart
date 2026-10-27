import 'package:meta/meta.dart';

/// Success value or error, so failures are explicit in signatures.
@immutable
sealed class Result<T, E> {
  const Result();

  /// True for [Ok].
  bool get isOk => this is Ok<T, E>;

  /// The value, or null for [Err].
  T? get valueOrNull => switch (this) {
    Ok<T, E>(:final value) => value,
    Err<T, E>() => null,
  };

  /// The error, or null for [Ok].
  E? get errorOrNull => switch (this) {
    Ok<T, E>() => null,
    Err<T, E>(:final error) => error,
  };

  /// Folds both cases into one value.
  R when<R>({
    required R Function(T value) ok,
    required R Function(E error) err,
  }) => switch (this) {
    Ok<T, E>(:final value) => ok(value),
    Err<T, E>(:final error) => err(error),
  };

  /// Transforms the value of an [Ok]; an [Err] is returned unchanged.
  Result<U, E> map<U>(U Function(T value) f) => switch (this) {
    Ok<T, E>(:final value) => Ok(f(value)),
    Err<T, E>(:final error) => Err(error),
  };
}

/// Successful [Result].
final class Ok<T, E> extends Result<T, E> {
  /// Creates a success.
  const Ok(this.value);

  /// The value.
  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T, E> && other.value == value;

  @override
  int get hashCode => Object.hash('Ok', value);
}

/// Failed [Result].
final class Err<T, E> extends Result<T, E> {
  /// Creates a failure.
  const Err(this.error);

  /// The error.
  final E error;

  @override
  bool operator ==(Object other) => other is Err<T, E> && other.error == error;

  @override
  int get hashCode => Object.hash('Err', error);
}
