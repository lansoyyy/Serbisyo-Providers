# Copilot Instructions for `hanap_raket`

## Overview
`hanap_raket` is a Flutter-based service marketplace application. It features a modern UI/UX design inspired by professional platforms like LinkedIn. The app includes multiple tabs for service discovery, booking, chat, and profile management, along with a splash screen and floating navigation bar.

### Key Components
- **Screens** (`lib/screens/`):
  - `main_screen.dart`: The main navigation shell with a floating bottom navigation bar.
  - `splash_screen.dart`: Displays the app's splash screen with animations.
  - Tabs (`lib/screens/tabs/`):
    - `home_tab.dart`: Service discovery interface.
    - `services_tab.dart`: Service browsing and filtering.
    - `booking_tab.dart`: Appointment management.
    - `chat_tab.dart`: Messaging interface.
    - `profile_tab.dart`: User profile and settings.

- **Widgets** (`lib/widgets/`):
  - Custom reusable widgets like `TextWidget`, `LoadingIndicatorWidget`, and `TouchableWidget`.

- **Utilities** (`lib/utils/`):
  - `colors.dart`: Centralized color definitions.
  - `navigations.dart`: Navigation helpers.

### Architecture
- **State Management**: Uses `GetX` for routing and state management.
- **Theming**: Centralized in `utils/colors.dart` and applied via `ThemeData` in `main.dart`.
- **Animations**: Extensive use of `AnimationController` and `CurvedAnimation` for smooth transitions.

## Developer Workflows
### Building and Running
1. Ensure Flutter is installed and set up.
2. Run the app:
   ```bash
   flutter run
   ```

### Debugging
- Use `flutter logs` to view runtime logs.
- Debug animations using the Flutter DevTools.

### Testing
- Widget tests are located in `test/`.
- Run tests:
  ```bash
  flutter test
  ```

## Project-Specific Conventions
- **Custom Widgets**: Use widgets from `lib/widgets/` for consistent UI patterns.
  - Example: Replace `Text` with `TextWidget` for standardized styling.
- **Navigation**: Use `GetX` for all navigation tasks.
  - Example:
    ```dart
    Get.toNamed('/main');
    ```
- **Colors**: Always use `AppColors` from `utils/colors.dart` for theming.

## Integration Points
- **External Libraries**:
  - `GetX`: For state management and navigation.
  - `FontAwesomeFlutter`: For icons.
  - `FlutterSpinkit`: For loading indicators.

## Examples
### Adding a New Tab
1. Create a new file in `lib/screens/tabs/`.
2. Add the tab to `_screens` in `main_screen.dart`.
3. Update the bottom navigation bar to include the new tab.

### Using a Custom Widget
Replace:
```dart
Text('Hello World');
```
With:
```dart
TextWidget(
  text: 'Hello World',
  fontSize: 16,
  color: AppColors.primary,
);
```
