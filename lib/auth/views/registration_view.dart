import 'package:flutter/material.dart';
import 'package:my_app/auth/viewmodels/registration_view_model.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/data/repositories/auth_repository.dart';

class RegistrationView extends StatefulWidget {
  const RegistrationView({super.key});

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  late final RegistrationViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _viewModel = RegistrationViewModel(
      authRepository: locator<AuthRepository>(),
    );
    _viewModel.loadAvailableRoles();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (_formKey.currentState!.validate()) {
      await _viewModel.register(
        _emailController.text,
        _passwordController.text,
        _firstNameController.text,
        _lastNameController.text,
      );

      if (!mounted) return;

      final state = _viewModel.registerState.value;
      if (state is AsyncData) {
        // Success - navigate back to login or show dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Регистрация успешна'),
              content: const Text(
                'Учётная запись создана. Администратор активирует её в течение 24 часов. '
                'После активации вы сможете войти в систему.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Back to login
                  },
                  child: const Text('Вернуться к входу'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Регистрация',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
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
                      // First name field
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'Имя',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите имя';
                          }
                          if (value.length < 2) {
                            return 'Имя должно быть не менее 2 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Last name field
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Фамилия',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите фамилию';
                          }
                          if (value.length < 2) {
                            return 'Фамилия должна быть не менее 2 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                          helperText: 'Минимум 8 символов, буквы и цифры',
                          helperMaxLines: 2,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите пароль';
                          }
                          if (value.length < 8) {
                            return 'Пароль должен быть не менее 8 символов';
                          }
                          if (!value.contains(RegExp(r'[a-z]'))) {
                            return 'Пароль должен содержать строчные буквы';
                          }
                          if (!value.contains(RegExp(r'[A-Z]'))) {
                            return 'Пароль должен содержать прописные буквы';
                          }
                          if (!value.contains(RegExp(r'[0-9]'))) {
                            return 'Пароль должен содержать цифры';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Role dropdown
                      ValueListenableBuilder<List<String>>(
                        valueListenable: _viewModel.availableRoles,
                        builder: (context, roles, _) {
                          return ValueListenableBuilder<String>(
                            valueListenable: _viewModel.selectedRole,
                            builder: (context, selectedRole, _) {
                              return DropdownButtonFormField<String>(
                                initialValue: selectedRole,
                                decoration: const InputDecoration(
                                  labelText: 'Роль',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                                items: roles
                                    .map((role) => DropdownMenuItem(
                                          value: role,
                                          child: Text(
                                            role == 'manager'
                                                ? 'Менеджер'
                                                : 'Сотрудник',
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    _viewModel.setRole(value);
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Выберите роль';
                                  }
                                  return null;
                                },
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Register button
                      ValueListenableBuilder<AsyncValue<void>>(
                        valueListenable: _viewModel.registerState,
                        builder: (context, state, child) {
                          return SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: state.isLoading ? null : _onRegister,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: state.isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Зарегистрироваться'),
                            ),
                          );
                        },
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
}
