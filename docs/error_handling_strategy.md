# 🚨 Error Handling Strategy

## 📋 Текущее состояние
**Проблема**: Нет единой стратегии обработки ошибок  
**Результат**: Каждый ViewModel может обрабатывать ошибки по-разному

---

## 🎯 Единая стратегия обработки ошибок

### 1. 🔄 Centralized Error Processing

#### Error Types:
```dart
sealed class AppError {
  const AppError();
  
  final String message;
  final String? code;
  final StackTrace? stackTrace;
}

class NetworkError extends AppError {
  const NetworkError(super.message, {super.code, super.stackTrace});
}

class ValidationError extends AppError {
  const ValidationError(super.message, {super.code, super.stackTrace});
}

class AuthError extends AppError {
  const AuthError(super.message, {super.code, super.stackTrace});
}

class UnknownError extends AppError {
  const UnknownError(super.message, {super.stackTrace});
}
```

#### Error Handler:
```dart
import 'package:my_app/core/utils/internal_notification/notify_service.dart';

class ErrorHandler {
  static final NotifyService _notifyService = locator<NotifyService>();
  
  static void handle(Object error, StackTrace? stackTrace) {
    final appError = _convertToAppError(error, stackTrace);
    
    // Логируем для отладки
    debugPrint('Error: ${appError.message}');
    if (appError.stackTrace != null) {
      debugPrint('StackTrace: ${appError.stackTrace}');
    }
    
    // Показываем пользователю
    _notifyUser(appError);
  }
  
  static AppError _convertToAppError(Object error, StackTrace? stackTrace) {
    if (error is AppError) return error;
    
    // Конвертируем известные типы ошибок
    if (error is SocketException) {
      return NetworkError('No internet connection', code: 'NETWORK_ERROR');
    }
    
    if (error is TimeoutException) {
      return NetworkError('Request timeout', code: 'TIMEOUT');
    }
    
    if (error is FormatException) {
      return ValidationError('Invalid data format', code: 'FORMAT_ERROR');
    }
    
    // По умолчанию
    return UnknownError(error.toString(), stackTrace: stackTrace);
  }
  
  static void _notifyUser(AppError error) {
    switch (error.runtimeType) {
      case NetworkError:
        _notifyService.showError(error.message, duration: const Duration(seconds: 5));
        break;
        
      case ValidationError:
        _notifyService.showError(error.message, duration: const Duration(seconds: 3));
        break;
        
      case AuthError:
        _notifyService.showError(error.message, duration: const Duration(seconds: 4));
        break;
        
      default:
        _notifyService.showError('Something went wrong', duration: const Duration(seconds: 3));
        break;
    }
  }
}
```

---

## 2. 🎯 ViewModel Error Handling Pattern

### ✅ Правильный шаблон:
```dart
class ExampleViewModel {
  final ExampleRepository _repository;
  final stateNotifier = ValueNotifier<AsyncValue<List<Item>>>(const AsyncLoading());
  
  ExampleViewModel({required ExampleRepository repository})
      : _repository = repository;
  
  Future<void> loadData() async {
    stateNotifier.value = const AsyncLoading();
    
    try {
      final data = await _repository.getData();
      stateNotifier.value = AsyncData(data);
    } catch (error, stackTrace) {
      // ✅ Единая обработка ошибок
      ErrorHandler.handle(error, stackTrace);
      stateNotifier.value = AsyncError('Failed to load data');
    }
  }
  
  Future<void> createItem(Item item) async {
    try {
      await _repository.create(item);
      await loadData(); // Перезагружаем данные
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      // Не меняем state - UI покажет ошибку через NotifyService
    }
  }
  
  void dispose() {
    stateNotifier.dispose();
  }
}
```

### ❌ Распростленные ошибки:
```dart
class BadViewModel {
  final stateNotifier = ValueNotifier<AsyncValue<List<Item>>>(const AsyncLoading());
  
  Future<void> loadData() async {
    try {
      final data = await _repository.getData();
      stateNotifier.value = AsyncData(data);
    } catch (e) {
      // ❌ Разная обработка ошибок
      stateNotifier.value = AsyncError(e.toString());
      // ❌ Нет логирования
      // ❌ Нет уведомления пользователя
    }
  }
}
```

---

## 3. 🎨 UI Error Display

### ✅ Правильное использование:
```dart
class ExampleView extends StatefulWidget {
  const ExampleView({super.key});

  @override
  State<ExampleView> createState() => _ExampleViewState();
}

class _ExampleViewState extends State<ExampleView> {
  late final ExampleViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ExampleViewModel(repository: locator<ExampleRepository>());
    _viewModel.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<AsyncValue<List<Item>>>(
        valueListenable: _viewModel.stateNotifier,
        builder: (context, asyncValue, _) {
          return asyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            data: (items) => ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => ListTile(title: Text(items[index].name)),
            ),
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load data',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _viewModel.loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
```

---

## 4. 🔄 Repository Error Handling

### ✅ Правильный шаблон:
```dart
class ExampleRepository {
  final ApiService _apiService;
  
  ExampleRepository({required ApiService apiService})
      : _apiService = apiService;
  
  Future<List<Item>> getItems() async {
    try {
      final response = await _apiService.get('/items');
      
      if (response.statusCode != 200) {
        throw NetworkError(
          'Server error: ${response.statusCode}',
          code: 'SERVER_ERROR_${response.statusCode}'
        );
      }
      
      return (response.data['items'] as List)
          .map((item) => Item.fromJson(item))
          .toList();
          
    } on SocketException catch (e) {
      throw NetworkError('Network connection failed', stackTrace: e.stackTrace);
    } on TimeoutException catch (e) {
      throw NetworkError('Request timeout', stackTrace: e.stackTrace);
    } on FormatException catch (e) {
      throw ValidationError('Invalid response format', stackTrace: e.stackTrace);
    } catch (e, stackTrace) {
      throw UnknownError(e.toString(), stackTrace: stackTrace);
    }
  }
  
  Future<Item> createItem(Item item) async {
    try {
      final response = await _apiService.post('/items', item.toJson());
      
      if (response.statusCode != 201) {
        throw NetworkError('Failed to create item');
      }
      
      return Item.fromJson(response.data);
      
    } catch (e, stackTrace) {
      throw UnknownError('Create item failed: ${e.toString()}', stackTrace: stackTrace);
    }
  }
}
```

---

## 5. 🎯 Specific Error Scenarios

### Authentication Errors:
```dart
class AuthRepository {
  Future<User> login(String email, String password) async {
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });
      
      if (response.statusCode == 401) {
        throw AuthError('Invalid email or password', code: 'INVALID_CREDENTIALS');
      }
      
      if (response.statusCode == 403) {
        throw AuthError('Account locked', code: 'ACCOUNT_LOCKED');
      }
      
      return User.fromJson(response.data);
      
    } on SocketException catch (e) {
      throw NetworkError('Check internet connection', code: 'NETWORK_ERROR');
    } catch (e, stackTrace) {
      throw UnknownError('Login failed: ${e.toString()}', stackTrace: stackTrace);
    }
  }
}
```

### Validation Errors:
```dart
class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Invalid email format';
    }
    
    return null; // ✅ Validation passed
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null; // ✅ Validation passed
  }
}
```

---

## 6. 🔧 NotifyService Integration

### Enhanced NotifyService:
```dart
class NotifyService {
  final ValueNotifier<NotificationData?> _notificationNotifier = 
      ValueNotifier<NotificationData?>(null);
  
  ValueNotifier<NotificationData?> get notificationNotifier => _notificationNotifier;
  
  void showError(String message, {Duration? duration}) {
    _showNotification(
      NotificationData.error(
        message: message,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }
  
  void showSuccess(String message, {Duration? duration}) {
    _showNotification(
      NotificationData.success(
        message: message,
        duration: duration ?? const Duration(seconds: 2),
      ),
    );
  }
  
  void showInfo(String message, {Duration? duration}) {
    _showNotification(
      NotificationData.info(
        message: message,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }
  
  void _showNotification(NotificationData notification) {
    _notificationNotifier.value = notification;
    
    // Автоматически скрываем через duration
    Future.delayed(notification.duration, () {
      if (_notificationNotifier.value == notification) {
        _notificationNotifier.value = null;
      }
    });
  }
}

class NotificationData {
  final String message;
  final NotificationType type;
  final Duration duration;
  
  const NotificationData({
    required this.message,
    required this.type,
    required this.duration,
  });
  
  factory NotificationData.error(String message, {Duration? duration}) =>
      NotificationData(
        message: message,
        type: NotificationType.error,
        duration: duration ?? const Duration(seconds: 3),
      );
      
  factory NotificationData.success(String message, {Duration? duration}) =>
      NotificationData(
        message: message,
        type: NotificationType.success,
        duration: duration ?? const Duration(seconds: 2),
      );
      
  factory NotificationData.info(String message, {Duration? duration}) =>
      NotificationData(
        message: message,
        type: NotificationType.info,
        duration: duration ?? const Duration(seconds: 3),
      );
}

enum NotificationType { error, success, info }
```

---

## 7. 📝 Implementation Checklist

### Для каждого ViewModel:
```markdown
- [ ] Все async операции обернуты в try-catch
- [ ] Используется ErrorHandler.handle() для обработки ошибок
- [ ] Состояние ошибки передается в UI через AsyncValue
- [ ] Есть retry функциональность
- [ ] Dispose метод корректно реализован
```

### Для Repository:
```markdown
- [ ] Все сетевые ошибки обернуты в кастомные типы
- [ ] HTTP коды обрабатываются корректно
- [ ] Timeout ошибки обрабатываются отдельно
- [ ] JSON ошибки валидируются
```

### Для UI:
```markdown
- [ ] Используется AsyncValue.when() для состояний
- [ ] Error state показывает понятное сообщение
- [ ] Есть retry кнопка для критических ошибок
- [ ] Loading state показывает прогресс
- [ ] Success state показывает данные
```

---

## 🎯 Практический пример для Login

### LoginViewModel:
```dart
class LoginViewModel {
  final AuthRepository _authRepository;
  final RouterService _routerService;
  
  final loginState = ValueNotifier<AsyncValue<void>>(const AsyncData(null));
  
  LoginViewModel({
    required AuthRepository authRepository,
    required RouterService routerService,
  }) : _authRepository = authRepository,
       _routerService = routerService;
  
  Future<void> login(String email, String password) async {
    // Валидация
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      ErrorHandler.handle(ValidationError(emailError));
      return;
    }
    
    final passwordError = Validators.validatePassword(password);
    if (passwordError != null) {
      ErrorHandler.handle(ValidationError(passwordError));
      return;
    }
    
    // Асинхронная операция
    loginState.value = const AsyncLoading();
    
    try {
      await _authRepository.login(email, password);
      loginState.value = const AsyncData(null);
      _routerService.go('/dashboard');
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      loginState.value = AsyncError('Login failed');
    }
  }
  
  void dispose() {
    loginState.dispose();
  }
}
```

---

**Рекомендация**: Внедрить эту стратегию с первого ViewModel (Login) и использовать как шаблон для всех остальных.

**Последнее обновление**: 2025-11-28