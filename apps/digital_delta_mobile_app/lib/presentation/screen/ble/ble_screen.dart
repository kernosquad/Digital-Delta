import 'package:flutter/material.dart';

import '../mesh/mesh_scan_screen.dart';

/// Backwards-compatible alias — the BLE scanner is now one unified screen
/// together with the mesh network view. Navigation to `/ble` opens the same
/// `MeshScanScreen` as `/mesh-network`.
class BleScreen extends StatelessWidget {
  const BleScreen({super.key});

  @override
  Widget build(BuildContext context) => const MeshScanScreen();
}
