// mesh_network_screen.dart — delegates to the unified MeshScanScreen.
// Kept for routes backwards compatibility.
export 'mesh_scan_screen.dart' show MeshScanScreen;

import 'package:flutter/material.dart';

import 'mesh_scan_screen.dart';

/// Backwards-compatible alias — navigation to `/mesh-network` now loads the
/// unified `MeshScanScreen` which combines BLE scanning and mesh topology.
class MeshNetworkScreen extends StatelessWidget {
  const MeshNetworkScreen({super.key});

  @override
  Widget build(BuildContext context) => const MeshScanScreen();
}
