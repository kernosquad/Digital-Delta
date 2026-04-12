# WelcomeMate Flutter Project - Comprehensive Generation Prompt

Use this prompt to replicate the exact project structure, architecture, design patterns, and coding style for similar Flutter projects.

---

## 📋 PROJECT OVERVIEW

**Project Name**: WelcomeMate
**Type**: Flutter Mobile Application
**Architecture Pattern**: Clean Architecture (Domain-Driven Design)
**State Management**: Flutter Riverpod 3.x
**Dependency Injection**: GetIt
**Min SDK**: ^3.8.1
**Target Platforms**: Android, iOS, Web

---

## 🏗️ FOLDER STRUCTURE & ARCHITECTURE

### Root Level Organization

```
project_root/
├── lib/                          # Main Dart source code
├── android/                       # Android native code
├── ios/                           # iOS native code
├── assets/                        # Images, fonts, animations, icons
├── build/                         # Build outputs
├── pubspec.yaml                   # Dependencies & configuration
├── analysis_options.yaml          # Lint rules
├── devtools_options.yaml          # DevTools configuration
├── README.md                      # Project documentation
```

### lib/ Structure (Clean Architecture Pattern)

```
lib/
├── main.dart                      # Entry point with ProviderScope setup
├── welcome_mate.dart              # Root widget with MaterialApp config
├── injection_container.dart       # DI setup orchestration
│
├── domain/                        # Domain Layer (Business Logic)
│   ├── enum/                      # Enums used across domain
│   ├── model/                     # Domain models
│   │   ├── auth/                 # Auth domain models
│   │   ├── career/               # Career domain models
│   │   ├── chat/                 # Chat domain models
│   │   ├── checklist/            # Checklist domain models
│   │   ├── community/            # Community domain models
│   │   ├── emergency/            # Emergency domain models
│   │   ├── guide/                # Guide domain models
│   │   ├── nav_item/             # Navigation item models
│   │   └── pagination/           # Pagination models
│   ├── repository/               # Repository interfaces (contracts)
│   │   ├── auth_repository.dart
│   │   ├── chat_repository.dart
│   │   ├── career_repository.dart
│   │   └── [feature]_repository.dart
│   ├── usecase/                  # Use cases / business logic
│   │   ├── auth/
│   │   ├── career/
│   │   ├── chat/
│   │   ├── checklist/
│   │   ├── community/
│   │   ├── emergency/
│   │   ├── guide/
│   │   └── onboarding/
│   └── util/
│       ├── failure.dart          # Error/Failure handling (Freezed)
│       └── result.dart           # Result type wrapper (Freezed)
│
├── data/                          # Data Layer (Data Source & Repository Implementation)
│   ├── datasource/
│   │   ├── local/               # Local data sources (SharedPreferences)
│   │   │   └── source/
│   │   │       ├── auth_local_data_source.dart (abstract)
│   │   │       ├── auth_local_data_source_impl.dart
│   │   │       └── settings_local_data_source_impl.dart
│   │   │
│   │   └── remote/              # Remote data sources (API)
│   │       ├── api/
│   │       │   ├── auth_api.dart (abstract)
│   │       │   ├── auth_api_impl.dart
│   │       │   ├── career_api.dart (abstract)
│   │       │   ├── career_api_impl.dart
│   │       │   └── [feature]_api[_impl].dart
│   │       ├── model/
│   │       │   ├── request/     # API request models
│   │       │   │   ├── auth/
│   │       │   │   ├── career/
│   │       │   │   └── [feature]/
│   │       │   └── response/    # API response models
│   │       │       ├── auth/
│   │       │       └── [feature]/
│   │       └── util/
│   │           ├── api_client.dart
│   │           ├── auth_interceptor.dart
│   │           ├── logging_interceptor.dart
│   │           └── json_parser.dart
│   │
│   ├── mapper/                   # Data to Domain model conversion
│   │   ├── auth/
│   │   ├── career/
│   │   ├── chat/
│   │   ├── checklist/
│   │   ├── community/
│   │   ├── emergency/
│   │   ├── guide/
│   │   └── pagination/
│   │
│   └── repository/              # Repository implementations
│       ├── auth_repository_impl.dart
│       ├── career_repository_impl.dart
│       ├── chat_repository_impl.dart
│       ├── checklist_repository_impl.dart
│       ├── community_repository_impl.dart
│       ├── emergency_repository_impl.dart
│       ├── guide_repository_impl.dart
│       └── settings_repository_impl.dart
│
├── presentation/                  # Presentation Layer (UI)
│   ├── theme/                    # Global theme & styling
│   │   ├── app_theme.dart       # Main theme (light/dark)
│   │   ├── color.dart           # Color constants
│   │   ├── text_theme.dart      # Text styles using flutter_screenutil
│   │   └── text_styles.dart     # Additional text styling
│   │
│   ├── common/                   # Shared widgets & utilities
│   │   ├── widget/
│   │   │   ├── custom_button.dart
│   │   │   ├── custom_form_field.dart
│   │   │   └── [shared_widget].dart
│   │   └── [other common utilities]
│   │
│   ├── dialog/                   # Dialog components
│   │   └── [dialog_widgets].dart
│   │
│   ├── screen/                   # Feature screens
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── onboarding/
│   │   │   └── onboarding_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── notifier/
│   │   │   │   ├── auth_notifier.dart
│   │   │   │   └── provider.dart
│   │   │   ├── state/
│   │   │   │   └── auth_ui_state.dart (Freezed)
│   │   │   └── widget/
│   │   │       ├── auth_divider.dart
│   │   │       ├── auth_header.dart
│   │   │       ├── social_login_section.dart
│   │   │       └── [auth_widget].dart
│   │   │
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   └── widget/
│   │   │
│   │   ├── career/
│   │   │   ├── career_screen.dart
│   │   │   ├── notifier/
│   │   │   └── widget/
│   │   │
│   │   ├── chat/
│   │   │   ├── chat_screen.dart
│   │   │   ├── notifier/
│   │   │   └── widget/
│   │   │
│   │   ├── checklist/
│   │   │   ├── checklist_screen.dart
│   │   │   ├── notifier/
│   │   │   └── widget/
│   │   │
│   │   ├── community/
│   │   │   ├── community_screen.dart
│   │   │   ├── notifier/
│   │   │   └── widget/
│   │   │
│   │   ├── emergency/
│   │   │   ├── emergency_screen.dart
│   │   │   ├── notifier/
│   │   │   └── widget/
│   │   │
│   │   ├── guide/
│   │   │   ├── guide_screen.dart
│   │   │   ├── notifier/
│   │   │   └── widget/
│   │   │
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   ├── notifier/
│   │   │   └── widget/
│   │   │
│   │   ├── main/
│   │   │   ├── main_screen.dart
│   │   │   ├── notifier/
│   │   │   └── widget/
│   │   │
│   │   ├── more/
│   │   │   ├── more_screen.dart
│   │   │   ├── notifier/
│   │   │   └── widget/
│   │   │
│   │   └── nearby/
│   │       ├── nearby_screen.dart
│   │       ├── notifier/
│   │       └── widget/
│   │
│   ├── util/
│   │   ├── routes.dart           # Route generation & navigation
│   │   ├── toaster.dart          # Toast notifications utility
│   │   └── [presentation utilities]
│   │
│   └── [other presentation utilities]
│
└── di/                            # Dependency Injection Modules
    ├── cache_module.dart         # SharedPreferences & cache setup
    ├── data_source_module.dart   # Local & remote data source registration
    ├── network_module.dart       # Dio, interceptors, API clients setup
    ├── repository_module.dart    # Repository implementations registration
    ├── service_module.dart       # Service registration
    └── use_case_module.dart      # Use case registration
```

### assets/ Structure

```
assets/
├── animations/
│   ├── live_chatbot.json
│   ├── welcome.json
│   └── world_map.json
├── fonts/
│   └── SF-Pro-Display-Regular.otf
├── icons/
│   └── [svg/png icons]
├── images/
│   └── [image assets]
└── logo/
    └── [logo files]
```

---

## 📦 DEPENDENCIES & TECH STACK

### Core Flutter

- **flutter_riverpod**: ^2.6.1 - State management
- **flutter_screenutil**: ^5.9.3 - Responsive UI scaling
- **get_it**: ^8.0.3 - Service locator / Dependency injection

### UI & Design

- **flutter_svg**: ^2.0.17 - SVG rendering
- **cached_network_image**: ^3.4.1 - Image caching
- **lottie**: ^3.3.1 - Animation support
- **flutter_animate**: ^4.0.0 - Additional animations
- **toastification**: ^3.0.3 - Toast notifications
- **shimmer**: ^3.0.0 - Loading shimmer effect
- **device_preview**: ^1.2.0 - Device preview testing
- **percent_indicator**: ^4.2.5 - Progress indicators
- **confetti**: ^0.8.0 - Confetti animations
- **simple_ripple_animation**: ^0.1.0 - Ripple effects

### Forms & Validation

- **flutter_form_builder**: ^10.1.0 - Form management
- **form_builder_validators**: ^11.2.0 - Form validation

### HTTP & Networking

- **dio**: ^5.7.0 - HTTP client
- **http_parser**: ^4.0.0 - HTTP parsing utilities
- **jwt_decoder**: ^2.0.1 - JWT token decoding
- **google_sign_in**: ^6.3.0 - Social login (Google)

### Data Persistence

- **shared_preferences**: ^2.3.5 - Local key-value storage
- **path_provider**: ^2.1.5 - File system paths

### Serialization & Code Generation

- **json_annotation**: ^4.9.0 - JSON serialization annotations
- **freezed**: ^2.5.7 - Immutable model generation
- **freezed_annotation**: ^2.4.4 - Freezed annotations
- **build_runner**: ^2.4.13 - Code generation (dev)
- **json_serializable**: ^6.9.4 - JSON serialization (dev)

### Localization & Formatting

- **intl**: ^0.20.2 - Internationalization
- **google_fonts**: ^6.2.1 - Google Fonts support

### Media & File Handling

- **image_picker**: ^1.1.2 - Image selection
- **file_picker**: ^10.2.0 - File selection
- **record**: ^6.0.0 - Audio recording
- **just_audio**: ^0.9.36 - Audio playback
- **flutter_tts**: ^4.2.3 - Text-to-speech

### Pagination & Lists

- **infinite_scroll_pagination**: ^4.0.0 - Infinite scrolling

### UI Components

- **flutter_card_swiper**: ^7.1.0 - Card swiper
- **carousel_slider_plus**: ^7.1.1 - Carousel/Slider
- **flutter_layout_grid**: ^2.0.8 - Advanced grid layouts
- **flutter_staggered_grid_view**: ^0.7.0 - Staggered grids
- **dotted_border**: ^2.1.0 - Dotted borders
- **avatar_glow**: ^3.0.1 - Avatar glowing effect
- **stepper_list_view**: ^0.0.2 - Stepper/timeline views
- **circular_countdown_timer**: ^0.2.4 - Countdown timers
- **animate_do**: ^4.2.0 - Animation library
- **flutter_spinkit**: ^5.2.1 - Loading spinners
- **animated_leaderboard**: ^0.1.4 - Leaderboard animation

### Content Display

- **flutter_html**: ^3.0.0 - HTML rendering
- **flutter_markdown**: ^0.7.4+1 - Markdown rendering

### Utilities

- **logging**: ^1.2.0 - Logging utility
- **logger**: ^2.5.0 - Advanced logging
- **url_launcher**: ^6.3.1 - URL launching
- **share_plus**: ^10.1.4 - Share functionality
- **permission_handler**: ^11.3.1 - Permission management
- **dartz**: ^0.10.1 - Functional programming utilities
- **flutter_launcher_icons**: ^0.13.1 - App icon generation
- **flutter_native_splash**: ^2.3.1 - Native splash screen

### Dev Dependencies

- **flutter_test**: ^3.x - Flutter testing
- **flutter_lints**: ^5.0.0 - Lint rules

---

## 🎨 DESIGN PATTERNS & CONVENTIONS

### 1. Clean Architecture Pattern

**Three-Layer Architecture:**

- **Domain Layer**: Pure business logic, independent of frameworks
- **Data Layer**: Data sources and repository implementations
- **Presentation Layer**: UI and state management

**Communication Flow:**

```
Presentation → Domain (Use Cases) → Domain (Repositories) → Data → API/Local
     ↑                                                              ↓
     ←──────────────────────────────────────────────────────────────
```

### 2. State Management: Flutter Riverpod

**Pattern Used:**

- `StateNotifierProvider` for mutable state management
- `FutureProvider` for async operations
- `Provider` for computed values
- State classes using `Freezed` for immutability

**Example Structure:**

```dart
// provider.dart
final notifierProvider = StateNotifierProvider((ref) => Notifier());

// notifier.dart
class Notifier extends StateNotifier<UiState> {
  Notifier() : super(const UiState.initial());

  Future<void> loadData() async {
    state = const UiState.loading();
    // business logic
    state = UiState.success(data: result);
  }
}

// ui_state.dart
@freezed
class UiState with _$UiState {
  const factory UiState.initial() = InitialState;
  const factory UiState.loading() = LoadingState;
  const factory UiState.success({required Data data}) = SuccessState;
  const factory UiState.error(String message) = ErrorState;
}
```

### 3. Repository Pattern

**Abstract Repository (Domain):**

```dart
abstract class FeatureRepository {
  Future<SomeModel> getData();
}
```

**Implementation (Data):**

```dart
class FeatureRepositoryImpl implements FeatureRepository {
  final FeatureRemoteDataSource remoteDataSource;

  FeatureRepositoryImpl({required this.remoteDataSource});

  @override
  Future<SomeModel> getData() {
    return remoteDataSource.getData();
  }
}
```

### 4. Use Case Pattern

**Standard Structure:**

```dart
class GetDataUseCase {
  final FeatureRepository _repository;

  GetDataUseCase({required FeatureRepository repository})
    : _repository = repository;

  Future<Result<SomeModel>> call({required String param}) async {
    return await _repository
        .getData(param: param)
        .then((data) => Result.success(data))
        .onError((Failure failure, stackTrace) => Result.failure(failure));
  }
}
```

### 5. Error Handling: Freezed Union Types

**Failure Type:**

```dart
@freezed
class Failure with _$Failure {
  const factory Failure.serverException({
    required String message,
    required int statusCode,
    dynamic data,
  }) = ServerException;

  const factory Failure.connectionException({required String message}) =
    ConnectionException;
  // ... other failure types
}
```

**Result Type:**

```dart
@freezed
class Result<T> with _$Result<T> {
  const factory Result.success(T value) = SuccessResult;
  const factory Result.failure(Failure failure) = FailureResult;
}
```

**Usage in Screens:**

```dart
result.when(
  success: (data) {
    // Handle success
  },
  failure: (failure) {
    // Handle failure
  },
);
```

### 6. Dependency Injection with GetIt

**Setup Pattern:**

```dart
// injection_container.dart
final GetIt getIt = GetIt.instance;

Future<void> setup() async {
  await setUpCacheModule();
  await getIt.allReady();
  await setUpNetworkModule();
  await setUpDataSourceModule();
  await setUpRepositoryModule();
  await setUpUseCaseModule();
}

// di/network_module.dart
Future<void> setUpNetworkModule() async {
  getIt.registerLazySingleton<Dio>(() => Dio(...));
  getIt.registerLazySingleton<AuthApi>(() => AuthApiImpl(client: getIt()));
}

// di/repository_module.dart
Future<void> setUpRepositoryModule() async {
  getIt.registerLazySingleton<FeatureRepository>(
    () => FeatureRepositoryImpl(remoteDataSource: getIt()),
  );
}

// di/use_case_module.dart
Future<void> setUpUseCaseModule() async {
  getIt.registerLazySingleton<GetDataUseCase>(
    () => GetDataUseCase(repository: getIt()),
  );
}
```

---

## 📝 NAMING CONVENTIONS

### Files & Directories

- **Lowercase with underscores** for file/folder names: `auth_notifier.dart`, `login_screen.dart`
- **ScreenUtil** suffix for responsive sizing: Width → `.w`, Height → `.h`, FontSize → `.sp`

### Classes

- **PascalCase**: `AuthNotifier`, `LoginScreen`, `AuthRepository`
- **Suffix conventions:**
  - Screens: `XyzScreen`
  - Notifiers: `XyzNotifier`
  - Repositories: `XyzRepository` (interface), `XyzRepositoryImpl` (implementation)
  - APIs: `XyzApi` (interface), `XyzApiImpl` (implementation)
  - Data Sources: `XyzDataSource` (interface), `XyzDataSourceImpl` (implementation)
  - Use Cases: `GetXyzUseCase`, `CreateXyzUseCase`, `UpdateXyzUseCase`, `DeleteXyzUseCase`

### Variables & Parameters

- **camelCase**: `userName`, `isLoading`, `authToken`
- **Private variables**: Leading underscore: `_privateVar`
- **Constants**: `UPPER_SNAKE_CASE` or `lowerCamelCase` depending on context

### Providers

- **Provider suffix**: `authNotifierProvider`, `userProvider`, `chatListProvider`
- **Type alias for clarity**: `typedef AuthNotifierProvider = StateNotifierProvider<AuthNotifier, AuthUiState>;`

---

## 🎯 CODE STYLE & PATTERNS

### 1. Import Organization

```dart
// 1. Dart imports
import 'dart:io';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports (alphabetically)
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 4. Relative project imports
import 'package:welcomemate/injection_container.dart';
import 'package:welcomemate/presentation/theme/app_theme.dart';
```

### 2. Widget Structure

```dart
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});

  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  // Declarations
  late GlobalKey<FormBuilderState> _formKey;

  // Handle initial setup
  @override
  void initState() {
    super.initState();
  }

  // Handle listeners
  void _setupListeners() {
    ref.listen<UiState>(provider, (previous, current) {
      current.maybeWhen(
        success: (data) {
          // Handle success
        },
        error: (message) {
          // Handle error
        },
        orElse: () {},
      );
    });
  }

  // Handle actions
  void _handleAction() async {
    await ref.read(notifierProvider.notifier).action();
  }

  // Build UI
  @override
  Widget build(BuildContext context) {
    _setupListeners();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [...],
        ),
      ),
    );
  }
}
```

### 3. Notifier Implementation

```dart
class MyNotifier extends StateNotifier<MyUiState> {
  MyNotifier() : super(const MyUiState.initial());

  Future<void> loadData() async {
    state = const MyUiState.loading();

    final useCase = getIt<GetDataUseCase>();
    final result = await useCase(params: 'value');

    state = result.when(
      success: (data) => MyUiState.success(data: data),
      failure: (failure) => MyUiState.error(failure.message),
    );
  }
}
```

### 4. Responsive Design with ScreenUtil

```dart
// Initialization in root widget
ScreenUtilInit(
  designSize: const Size(375, 812),
  minTextAdapt: true,
  splitScreenMode: false,
  builder: (_, __) => MaterialApp(...),
)

// Usage in widgets
Container(
  width: 100.w,  // Responsive width
  height: 50.h,  // Responsive height
  margin: EdgeInsets.all(16.w),
  child: Text(
    'Title',
    style: TextStyle(fontSize: 18.sp), // Responsive font size
  ),
)
```

### 5. Color & Theme Usage

```dart
// colors in theme/color.dart
class AppColors {
  static const Color primarySurfaceDefault = Color(0xff00b262);
  static const Color dangerSurfaceDefault = Color(0xfff1113e);
  static const Color colorBackground = Color(0xFFF8F9FE);
}

// Access in code
Container(
  color: AppColors.colorBackground,
  child: Text(
    'Text',
    style: TextStyle(color: AppColors.primaryTextDefault),
  ),
)
```

### 6. API Interceptors

```dart
class AuthInterceptor extends Interceptor {
  final AuthLocalDataSource _authLocalDataSource;

  AuthInterceptor({required AuthLocalDataSource authLocalDataSource})
    : _authLocalDataSource = authLocalDataSource;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _authLocalDataSource.getAccessToken();
    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future onError(DioError err, ErrorInterceptorHandler handler) async {
    // Handle token refresh or error
    return handler.next(err);
  }
}
```

### 7. Navigation & Routing

```dart
// Initialization in welcome_mate.dart
MaterialApp(
  initialRoute: Routes.splash,
  onGenerateRoute: Routes.generateRoutes,
)

// Route definitions
class Routes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String main = '/main';

  static Route<dynamic> generateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}

// Navigation
Navigator.pushNamed(context, Routes.login);
Navigator.pushNamedAndRemoveUntil(context, Routes.main, (route) => false);
Navigator.pop(context);
```

### 8. Toast Notifications

```dart
class Toaster {
  static void showSuccess(BuildContext context, String message) {
    Toastification().show(
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: Text(message),
      duration: const Duration(seconds: 3),
    );
  }

  static void showError(BuildContext context, String message) {
    Toastification().show(
      type: ToastificationType.error,
      title: Text(message),
    );
  }
}

// Usage
Toaster.showSuccess(context, 'Success message');
```

---

## 📱 SCREEN STRUCTURE TEMPLATE

Each feature screen should follow this pattern:

```
lib/presentation/screen/feature/
├── feature_screen.dart          # Main screen widget
├── notifier/
│   ├── feature_notifier.dart    # State notifier
│   └── provider.dart            # Provider definition
├── state/
│   └── feature_ui_state.dart    # Freezed UI state definitions
└── widget/
    ├── feature_widget_1.dart
    ├── feature_widget_2.dart
    └── [smaller components]
```

**Each screen should:**

1. Use `ConsumerStatefulWidget` or `ConsumerWidget`
2. Have corresponding `Notifier` class for state
3. Define `UiState` with Freezed for state variants
4. Keep reusable widgets in `widget/` folder
5. Handle listeners with `ref.listen`
6. Show loading/error states clearly

---

## 🔧 DEVELOPMENT WORKFLOW

### Code Generation

After modifying models with `@freezed` annotations:

```bash
flutter pub run build_runner build  # Build once
flutter pub run build_runner watch  # Watch mode
```

### Project Setup

```bash
flutter pub get
flutter pub run build_runner build
flutter run
```

### Code Analysis

```bash
flutter analyze
```

### Formatting

```bash
dart format lib/
```

---

## 🎯 KEY ARCHITECTURAL DECISIONS

1. **Why Freezed?**
   - Generates copyWith, equality, and pattern matching
   - Immutable models reduce bugs
   - Type-safe union types for sealed classes

2. **Why Riverpod?**
   - Compile-time safe, no strings
   - Automatic dependency management
   - Better testability than Provider

3. **Why GetIt?**
   - Simple dependency injection
   - No reflection, explicit registration
   - Easy to understand and debug

4. **Why Dartz?**
   - Functional programming utilities
   - Better error handling patterns
   - Either/Result types for business logic

5. **Why Clean Architecture?**
   - Separation of concerns
   - Testable business logic
   - Independent of frameworks
   - Scalable project structure

---

## 📋 CHECKLIST FOR NEW FEATURES

When adding a new feature, follow this checklist:

- [ ] Create domain `model/feature/` files
- [ ] Create domain `repository/feature_repository.dart` (interface)
- [ ] Create domain `usecase/feature/` use case files
- [ ] Create data API files: `api/feature_api.dart` and `feature_api_impl.dart`
- [ ] Create data mapper in `mapper/feature/`
- [ ] Create data repository implementation: `data/repository/feature_repository_impl.dart`
- [ ] Register in DI: `di/network_module.dart`, `di/repository_module.dart`, `di/use_case_module.dart`
- [ ] Create presentation screen: `presentation/screen/feature/feature_screen.dart`
- [ ] Create notifier: `presentation/screen/feature/notifier/feature_notifier.dart`
- [ ] Create UI state: `presentation/screen/feature/state/feature_ui_state.dart`
- [ ] Create screen widgets in `presentation/screen/feature/widget/`
- [ ] Add route in `presentation/util/routes.dart`
- [ ] Run code generation: `flutter pub run build_runner build`
- [ ] Test the feature end-to-end

---

## 🚀 BEST PRACTICES

1. **Always use const constructors** for widgets when possible
2. **Use `super.key`** in widget constructors
3. **Avoid mutable state** in domain/data layers
4. **Keep notifiers focused** - one responsibility per notifier
5. **Use meaningful variable names** - avoid single letter variables
6. **Comment complex logic** but keep comments brief and accurate
7. **Test use cases and repositories** - they contain business logic
8. **Lazy register services** with GetIt when possible
9. **Use `maybeWhen` or `when`** for Freezed pattern matching
10. **Handle all UI states** - initial, loading, success, error
11. **Use `RefreshIndicator`** for manual refresh in lists
12. **Implement `FutureProvider`** for data that needs caching
13. **Use `riverpod_generator`** for complex provider logic if needed

---

## 🔗 PROJECT STRUCTURE SUMMARY

```
WelcomeMate Architecture:
├── Domain: Pure business logic (models, interfaces, use cases)
├── Data: Implementations (API clients, local storage, repositories)
├── Presentation: UI layer (screens, widgets, state management)
└── DI: Dependency injection configuration

Technologies:
├── State: Flutter Riverpod + Freezed
├── Network: Dio + Interceptors
├── Storage: SharedPreferences
├── DI: GetIt
├── Serialization: json_serializable + Freezed
└── Responsive: Flutter ScreenUtil
```

---

## 📄 EXAMPLE: COMPLETE FEATURE IMPLEMENTATION

See the structure above for a full working example of how features are implemented in this project. Each feature (Auth, Chat, Career, etc.) follows the identical pattern described in this document.

---

**Last Updated**: April 2026
**Version**: 1.0
**Architecture Pattern**: Clean Architecture with Riverpod State Management
