import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../../../../domain/enum/connection_type.dart';
import '../../../../../domain/model/connectivity/connectivity_status_model.dart';
import 'connectivity_data_source.dart';

class ConnectivityDataSourceImpl implements ConnectivityDataSource {
  final InternetConnection _internetConnection;
  final Connectivity _connectivity;

  ConnectivityDataSourceImpl({
    required InternetConnection internetConnection,
    required Connectivity connectivity,
  }) : _internetConnection = internetConnection,
       _connectivity = connectivity;

  @override
  Future<ConnectivityStatusModel> get currentStatus async {
    final hasInternet = await _internetConnection.hasInternetAccess;

    if (!hasInternet) {
      return const ConnectivityStatusModel.offline();
    }

    final type = await _resolveConnectionType();
    return ConnectivityStatusModel.online(type: type);
  }

  @override
  Stream<ConnectivityStatusModel> get onStatusChanged {
    // connectivity_plus fires immediately on ANY interface change
    // (wifi, mobile, bluetooth, ethernet, vpn) — so we use it as the
    // primary driver and validate real internet access for each event.
    return _connectivity.onConnectivityChanged.asyncMap((results) async {
      final allNone =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);

      if (allNone) return const ConnectivityStatusModel.offline();

      final hasInternet = await _internetConnection.hasInternetAccess;
      if (!hasInternet) return const ConnectivityStatusModel.offline();

      final type = _mapConnectionType(results);
      return ConnectivityStatusModel.online(type: type);
    });
  }

  Future<ConnectionType> _resolveConnectionType() async {
    final results = await _connectivity.checkConnectivity();
    return _mapConnectionType(results);
  }

  ConnectionType _mapConnectionType(List<ConnectivityResult> results) {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return ConnectionType.none;
    }
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectionType.wifi;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectionType.mobile;
    }
    if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectionType.ethernet;
    }
    if (results.contains(ConnectivityResult.bluetooth)) {
      return ConnectionType.bluetooth;
    }
    if (results.contains(ConnectivityResult.vpn)) {
      return ConnectionType.vpn;
    }
    return ConnectionType.other;
  }
}
