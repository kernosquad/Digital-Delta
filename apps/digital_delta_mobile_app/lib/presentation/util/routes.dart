import 'package:flutter/material.dart';

import '../screen/auth/key/key_provision_screen.dart';
import '../screen/auth/key/key_provisioning_screen.dart';
import '../screen/auth/login/login_screen.dart';
import '../screen/auth/otp/otp_setup_display_screen.dart';
import '../screen/auth/otp/otp_setup_screen.dart';
import '../screen/auth/otp/otp_verification_screen.dart';
import '../screen/auth/otp/otp_verify_screen.dart';
import '../screen/auth/register/register_screen.dart';
import '../screen/home/home_screen.dart';
import '../screen/main/main_screen.dart';
import '../screen/map/map_screen.dart';
import '../screen/mesh/mesh_chat_screen.dart';
import '../screen/mesh/mesh_network_screen.dart';
import '../screen/mesh/mesh_scan_screen.dart';
import '../screen/onboarding/onboarding_screen.dart';
import '../screen/fleet/drone_dispatch_screen.dart';
import '../screen/pod/pod_scanner_screen.dart';
import '../screen/routing/routing_screen.dart';
import '../screen/splash/splash_screen.dart';

class Routes {
  Routes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String home = '/home';
  static const String ble = '/ble';
  static const String otpSetup = '/otp-setup';
  static const String otpSetupDisplay = '/otp-setup-display';
  static const String otpVerify = '/otp-verify';
  static const String otpVerification = '/otp-verification';
  static const String keyProvision = '/key-provision';
  static const String keyProvisioning = '/key-provisioning';
  static const String meshNetwork = '/mesh-network';
  static const String meshScan = '/mesh-scan';
  static const String meshChat = '/mesh-chat';
  static const String podScanner = '/pod-scanner';
  static const String routing = '/routing';
  static const String droneDispatch = '/drone-dispatch';
  static const String map = '/map';

  static Route<dynamic> generateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case main:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case ble:
      case meshScan:
        return MaterialPageRoute(builder: (_) => const MeshScanScreen());
      case otpSetup:
        return MaterialPageRoute(builder: (_) => const OtpSetupScreen());
      case otpSetupDisplay:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OtpSetupDisplayScreen(
            secret: args['secret'] as String,
            otpauthUri: args['otpauthUri'] as String,
            deviceId: args['deviceId'] as String,
            userEmail: args['userEmail'] as String,
          ),
        );
      case otpVerify:
        final deviceId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(deviceId: deviceId),
        );
      case otpVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            deviceId: args['deviceId'] as String,
            secret: args['secret'] as String,
          ),
        );
      case keyProvision:
        return MaterialPageRoute(builder: (_) => const KeyProvisionScreen());
      case keyProvisioning:
        return MaterialPageRoute(builder: (_) => const KeyProvisioningScreen());
      case meshNetwork:
        return MaterialPageRoute(builder: (_) => const MeshScanScreen());
      case meshChat:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => MeshChatScreen(
            peerNodeUuid: args['peerNodeUuid'] as String,
            initialPeerName: args['peerName'] as String?,
          ),
        );
      case podScanner:
        return MaterialPageRoute(builder: (_) => const PodScannerScreen());
      case routing:
        return MaterialPageRoute(builder: (_) => const RoutingScreen());
      case droneDispatch:
        return MaterialPageRoute(builder: (_) => const DroneDispatchScreen());
      case map:
        return MaterialPageRoute(builder: (_) => const MapScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
