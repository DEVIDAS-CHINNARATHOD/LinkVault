// lib/core/errors/failures.dart

sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error. Please check your connection.']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Local storage error.']) : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication failed.']) : super(message);
}

class VaultFailure extends Failure {
  const VaultFailure([String message = 'Vault access denied.']) : super(message);
}

class EncryptionFailure extends Failure {
  const EncryptionFailure([String message = 'Encryption/decryption failed.']) : super(message);
}

class DuplicateFailure extends Failure {
  const DuplicateFailure([String message = 'This link already exists.']) : super(message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Resource not found.']) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'An unexpected error occurred.']) : super(message);
}

// lib/core/errors/result.dart

typedef Result<T> = ({T? data, Failure? error});

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => error == null;
  bool get isFailure => error != null;
  T get requireData => data as T;
}

Result<T> success<T>(T data) => (data: data, error: null);
Result<T> failure<T>(Failure error) => (data: null, error: error);
