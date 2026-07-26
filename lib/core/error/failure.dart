sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
