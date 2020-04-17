import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  final String token;

  const LoggedIn({@required this.token});

  @override
  List<Object> get props => [token];

  @override
  String toString() {
    return 'LoggedIn{token: $token}';
  }
}

class LoggedOut extends AuthEvent {}
