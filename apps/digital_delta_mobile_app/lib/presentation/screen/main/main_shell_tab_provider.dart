import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom navigation index for [MainScreen]:
/// 0 Home, 1 Sync (CRDT dashboard), 2 Map, 3 Fleet, 4 Profile.
final mainShellTabProvider = StateProvider<int>((ref) => 0);
