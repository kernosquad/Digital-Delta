import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.serverException({
    required String message,
    required int statusCode,
    dynamic data,
  }) = ServerException;

  const factory Failure.connectionException({required String message}) =
      ConnectionException;

  const factory Failure.unauthorizedException({required String message}) =
      UnauthorizedException;

  const factory Failure.validationException({
    required String message,
    Map<String, List<String>>? errors,
  }) = ValidationException;

  const factory Failure.unknownException({required String message}) =
      UnknownException;
}

extension FailureX on Failure {
  String get message => when(
    serverException: (msg, _, __) => msg,
    connectionException: (msg) => msg,
    unauthorizedException: (msg) => msg,
    validationException: (msg, __) => msg,
    unknownException: (msg) => msg,
  );
}
