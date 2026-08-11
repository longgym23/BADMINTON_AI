import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? errorCode;

  const Failure({required this.message, this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required super.message, super.errorCode});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.errorCode});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.errorCode});
}
