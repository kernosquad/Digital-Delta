import '../../../../../domain/model/connectivity/connectivity_status_model.dart';

abstract class ConnectivityDataSource {
  Future<ConnectivityStatusModel> get currentStatus;
  Stream<ConnectivityStatusModel> get onStatusChanged;
}
