import 'package:tripship/core/exceptions/tripship_exception.dart';

sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(TripShipException error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
  TripShipException? get errorOrNull =>
      this is Failure<T> ? (this as Failure<T>).error : null;

  R fold<R>(
    R Function(T data) onSuccess,
    R Function(TripShipException error) onFailure,
  ) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    } else {
      return onFailure((this as Failure<T>).error);
    }
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final TripShipException error;
  const Failure(this.error);
}
