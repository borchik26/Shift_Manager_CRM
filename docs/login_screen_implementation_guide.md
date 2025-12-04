# 🔐 Login Screen - Implementation Guide

## 🎯 Задача
Реализовать экран авторизации (Login Screen) для веб-приложения "Система управления сменами" с Mock-логикой.

---

## 📚 Входные данные

### 1. Референс UI
- **Файл**: `login.jpeg`
- **Стиль**: Clean, минималистичный дизайн
- **Цветовая схема**: Светло-серый фон, белая карточка, синяя кнопка

### 2. Стек технологий
- **Flutter**: Последняя версия
- **State Management**: ValueNotifier<AsyncValue<T>>
- **UI**: Material 3, Google Fonts (Inter или Roboto)
- **Forms**: GlobalKey<FormState>, TextFormField с валидаторами

### 3. Архитектура
- **Pattern**: MVVM
- **State Management**: ValueNotifier<AsyncValue<T>> (Simple Screen)
- **Mock Auth**: Без реального backend

---

## 🏗️ Архитектура (MVVM)

### 1. Model (`lib/data/models/user_model.dart`)

```dart
class User {
  final String id;
  final String email;
  final String name;
  final String role;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
    };
  }
}
```

---

### 2. ViewModel (`lib/auth/viewmodels/auth_view_model.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/repositories/auth_repository.dart';

class AuthViewModel {
  final AuthRepository _authRepository;
  
  // Simple Screen: используем ValueNotifier<AsyncValue<T>>
  final loginState = ValueNotifier<AsyncValue<void>>(const AsyncData(null));
  
  AuthViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;
  
  Future<void> login(String email, String password) async {
    loginState.value = const AsyncLoading();
    
    try {
      await _authRepository.login(email, password);
      loginState.value = const AsyncData(null);
      // Навигация будет обработана в View через RouterService
    } catch (e) {
      loginState.value = AsyncError(e.toString());
    }
  }
  
  void dispose() {
    loginState.dispose();
  }
}
```

---

### 3. View (`lib/auth/views/login_view.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/auth/viewmodels/auth_view_model.dart';
import 'package:my_app/data/repositories/auth_repository.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final AuthViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _viewModel = AuthViewModel(
      authRepository: locator<AuthRepository>(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Логотип или заголовок
                          Text(
                            'Вход в систему',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Система управления сменами',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Email поле
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'user@test.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF007AFF),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите email';
                              }
                              if (!value.contains('@')) {
                                return 'Введите корректный email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password поле
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Пароль',
                              hintText: '••••••',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF007AFF),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите пароль';
                              }
                              if (value.length < 6) {
                                return 'Пароль должен быть не менее 6 символов';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Сообщение об ошибке с ValueListenableBuilder
                          ValueListenableBuilder<AsyncValue<void>>(
                            valueListenable: _viewModel.loginState,
                            builder: (context, state, child) {
                              if (state is! AsyncError) {
                                return const SizedBox.shrink();
                              }
                              
                              return Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        state.error,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Кнопка входа с ValueListenableBuilder
                          ValueListenableBuilder<AsyncValue<void>>(
                            valueListenable: _viewModel.loginState,
                            builder: (context, state, child) {
                              return SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: state is AsyncLoading
                                      ? null
                                      : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF007AFF),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        const Color(0xFF007AFF).withOpacity(0.6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: state is AsyncLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Войти',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Подсказка для тестирования
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Тестовые данные:',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Email: user@test.com',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                Text(
                                  'Пароль: 123456',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    // Валидация формы
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Попытка входа
    await _viewModel.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    // Проверка успешности входа
    if (_viewModel.loginState.value is AsyncData && mounted) {
      // Навигация на главный экран
      locator<RouterService>().pushReplacementNamed('/dashboard');
    }
  }
}
```

---

## 📝 Checklist для реализации

### Подготовка:
- [ ] Убедиться, что `google_fonts` добавлен в `pubspec.yaml`
- [ ] Создать папку `lib/auth/` с подпапками (viewmodels, views)
- [ ] Убедиться, что `async_value.dart` создан в `lib/core/utils/`
- [ ] Обновить `User` модель в `lib/data/models/user_model.dart`

### Реализация:
- [ ] Создать `auth_view_model.dart` с `ValueNotifier<AsyncValue<T>>`
- [ ] Реализовать метод `login()` через AuthRepository
- [ ] Создать `login_view.dart` с формой
- [ ] Добавить валидацию полей (email, password)
- [ ] Реализовать показ/скрытие пароля
- [ ] Добавить состояние загрузки (CircularProgressIndicator)
- [ ] Добавить отображение ошибок через ValueListenableBuilder

### Стилизация:
- [ ] Фон страницы: #F5F7FA
- [ ] Карточка: белая, тень, скругление 16px
- [ ] Кнопка: #007AFF, высота 48px
- [ ] Шрифты: Google Fonts (Inter)
- [ ] Адаптивность: maxWidth 400px

### Интеграция:
- [ ] Добавить роут `/login` в `route_config.dart`
- [ ] Настроить редирект на `/dashboard` через RouterService

---

## 🎯 Ожидаемый результат

### Функциональность:
- ✅ Форма с валидацией email и пароля
- ✅ Показ/скрытие пароля
- ✅ Mock авторизация (2 секунды задержка)
- ✅ Состояние загрузки
- ✅ Отображение ошибок
- ✅ Редирект после успешного входа

### UI особенности:
- ✅ Светло-серый фон
- ✅ Центрированная белая карточка
- ✅ Синяя кнопка с лоадером
- ✅ Адаптивный дизайн
- ✅ Подсказка с тестовыми данными

### Тестовые credentials:
```
Email: user@test.com
Password: 123456
```

---

## 🔧 Тестовые credentials

Mock авторизация настроена в `MockApiService`:

```dart
// В lib/data/services/mock_api_service.dart
Future<User> login(String email, String password) async {
  await Future.delayed(const Duration(seconds: 1));
  
  if (email == 'admin@example.com' && password == 'password123') {
    return User(
      id: 'user_001',
      email: email,
      name: 'Администратор',
      role: 'admin',
    );
  }
  
  throw Exception('Неверный email или пароль');
}
```

**Тестовые данные:**
- Email: `admin@example.com`
- Пароль: `password123`

---

**Последнее обновление**: 2025-11-28  
**Статус**: Готов к реализации  
**Время реализации**: 2-3 часа