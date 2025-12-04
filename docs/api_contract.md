# API Contract - Shift Manager CRM

Контракт API для интеграции Frontend (Flutter) и Backend.

## 📋 Общая информация

**Base URL**: `https://api.example.com/v1`  
**Content-Type**: `application/json`  
**Authentication**: Bearer Token (JWT)

### Формат ответов

#### Успешный ответ
```json
{
  "success": true,
  "data": { ... },
  "message": "Success message"
}
```

#### Ошибка
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": { ... }
  }
}
```

### Коды ошибок
- `AUTH_FAILED` - Ошибка аутентификации
- `INVALID_TOKEN` - Невалидный токен
- `NOT_FOUND` - Ресурс не найден
- `VALIDATION_ERROR` - Ошибка валидации
- `PERMISSION_DENIED` - Недостаточно прав
- `SERVER_ERROR` - Внутренняя ошибка сервера

---

## 🔐 Authentication

### POST /auth/login
Аутентификация пользователя

**Request:**
```json
{
  "email": "admin@example.com",
  "password": "admin123"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "refresh_token_here",
    "expires_in": 3600,
    "user": {
      "id": "user_1",
      "email": "admin@example.com",
      "name": "Admin User",
      "role": "admin"
    }
  }
}
```

**Errors:**
- `401` - AUTH_FAILED: Неверный email или пароль
- `400` - VALIDATION_ERROR: Невалидные данные

---

### POST /auth/logout
Выход из системы

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

### POST /auth/refresh
Обновление токена

**Request:**
```json
{
  "refresh_token": "refresh_token_here"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "new_access_token",
    "expires_in": 3600
  }
}
```

---

### GET /auth/me
Получение информации о текущем пользователе

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "user_1",
    "email": "admin@example.com",
    "name": "Admin User",
    "role": "admin"
  }
}
```

---

## 👥 Employees

### GET /employees
Получение списка сотрудников

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `page` (optional): Номер страницы (default: 1)
- `limit` (optional): Количество на странице (default: 20)
- `status` (optional): Фильтр по статусу (active, inactive, on_leave)
- `search` (optional): Поиск по имени, email, телефону
- `position` (optional): Фильтр по должности

**Response (200):**
```json
{
  "success": true,
  "data": {
    "employees": [
      {
        "id": "emp_1",
        "first_name": "John",
        "last_name": "Doe",
        "email": "john.doe@example.com",
        "phone": "+1234567890",
        "position": "Manager",
        "status": "active",
        "hire_date": "2024-01-15T00:00:00Z",
        "avatar_url": "https://example.com/avatars/emp_1.jpg"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_items": 100,
      "items_per_page": 20
    }
  }
}
```

---

### GET /employees/:id
Получение информации о сотруднике

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "emp_1",
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "phone": "+1234567890",
    "position": "Manager",
    "status": "active",
    "hire_date": "2024-01-15T00:00:00Z",
    "avatar_url": "https://example.com/avatars/emp_1.jpg",
    "address": "123 Main St, City, Country",
    "emergency_contact": {
      "name": "Jane Doe",
      "phone": "+0987654321",
      "relationship": "Spouse"
    }
  }
}
```

**Errors:**
- `404` - NOT_FOUND: Сотрудник не найден

---

### POST /employees
Создание нового сотрудника

**Headers:**
```
Authorization: Bearer {token}
```

**Request:**
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "phone": "+1234567890",
  "position": "Manager",
  "hire_date": "2024-01-15T00:00:00Z",
  "address": "123 Main St, City, Country",
  "emergency_contact": {
    "name": "Jane Doe",
    "phone": "+0987654321",
    "relationship": "Spouse"
  }
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "emp_new",
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "phone": "+1234567890",
    "position": "Manager",
    "status": "active",
    "hire_date": "2024-01-15T00:00:00Z",
    "avatar_url": null
  },
  "message": "Employee created successfully"
}
```

**Errors:**
- `400` - VALIDATION_ERROR: Невалидные данные
- `409` - CONFLICT: Email уже существует

---

### PUT /employees/:id
Обновление информации о сотруднике

**Headers:**
```
Authorization: Bearer {token}
```

**Request:**
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "phone": "+1234567890",
  "position": "Senior Manager",
  "status": "active",
  "address": "456 New St, City, Country"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "emp_1",
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "phone": "+1234567890",
    "position": "Senior Manager",
    "status": "active",
    "hire_date": "2024-01-15T00:00:00Z",
    "avatar_url": "https://example.com/avatars/emp_1.jpg"
  },
  "message": "Employee updated successfully"
}
```

**Errors:**
- `404` - NOT_FOUND: Сотрудник не найден
- `400` - VALIDATION_ERROR: Невалидные данные

---

### DELETE /employees/:id
Удаление сотрудника (soft delete)

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Employee deleted successfully"
}
```

**Errors:**
- `404` - NOT_FOUND: Сотрудник не найден
- `403` - PERMISSION_DENIED: Недостаточно прав

---

## 📅 Shifts

### GET /shifts
Получение списка смен

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `start_date` (optional): Начало периода (ISO 8601)
- `end_date` (optional): Конец периода (ISO 8601)
- `employee_id` (optional): Фильтр по сотруднику
- `status` (optional): Фильтр по статусу (scheduled, in_progress, completed, cancelled)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "shifts": [
      {
        "id": "shift_1",
        "employee_id": "emp_1",
        "start_time": "2024-01-20T09:00:00Z",
        "end_time": "2024-01-20T17:00:00Z",
        "status": "scheduled",
        "notes": "Morning shift",
        "created_at": "2024-01-15T10:00:00Z",
        "updated_at": "2024-01-15T10:00:00Z"
      }
    ]
  }
}
```

---

### GET /shifts/:id
Получение информации о смене

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "shift_1",
    "employee_id": "emp_1",
    "employee": {
      "id": "emp_1",
      "first_name": "John",
      "last_name": "Doe",
      "position": "Manager"
    },
    "start_time": "2024-01-20T09:00:00Z",
    "end_time": "2024-01-20T17:00:00Z",
    "status": "scheduled",
    "notes": "Morning shift",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z"
  }
}
```

**Errors:**
- `404` - NOT_FOUND: Смена не найдена

---

### POST /shifts
Создание новой смены

**Headers:**
```
Authorization: Bearer {token}
```

**Request:**
```json
{
  "employee_id": "emp_1",
  "start_time": "2024-01-20T09:00:00Z",
  "end_time": "2024-01-20T17:00:00Z",
  "notes": "Morning shift"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "shift_new",
    "employee_id": "emp_1",
    "start_time": "2024-01-20T09:00:00Z",
    "end_time": "2024-01-20T17:00:00Z",
    "status": "scheduled",
    "notes": "Morning shift",
    "created_at": "2024-01-20T08:00:00Z",
    "updated_at": "2024-01-20T08:00:00Z"
  },
  "message": "Shift created successfully"
}
```

**Errors:**
- `400` - VALIDATION_ERROR: Невалидные данные
- `409` - CONFLICT: Конфликт с существующей сменой

---

### PUT /shifts/:id
Обновление смены

**Headers:**
```
Authorization: Bearer {token}
```

**Request:**
```json
{
  "employee_id": "emp_1",
  "start_time": "2024-01-20T10:00:00Z",
  "end_time": "2024-01-20T18:00:00Z",
  "status": "in_progress",
  "notes": "Updated shift"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "shift_1",
    "employee_id": "emp_1",
    "start_time": "2024-01-20T10:00:00Z",
    "end_time": "2024-01-20T18:00:00Z",
    "status": "in_progress",
    "notes": "Updated shift",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-20T09:30:00Z"
  },
  "message": "Shift updated successfully"
}
```

**Errors:**
- `404` - NOT_FOUND: Смена не найдена
- `400` - VALIDATION_ERROR: Невалидные данные

---

### DELETE /shifts/:id
Удаление смены

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Shift deleted successfully"
}
```

**Errors:**
- `404` - NOT_FOUND: Смена не найдена
- `403` - PERMISSION_DENIED: Недостаточно прав

---

## 📊 Statistics (Future)

### GET /statistics/dashboard
Получение статистики для дашборда

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "total_employees": 50,
    "active_employees": 45,
    "total_shifts_today": 20,
    "upcoming_shifts": 15,
    "completed_shifts_this_week": 100
  }
}
```

---

## 🔔 Notifications (Future)

### GET /notifications
Получение уведомлений

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `unread_only` (optional): Только непрочитанные (true/false)
- `limit` (optional): Количество (default: 20)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "notif_1",
        "type": "shift_reminder",
        "title": "Upcoming Shift",
        "message": "Your shift starts in 1 hour",
        "read": false,
        "created_at": "2024-01-20T08:00:00Z"
      }
    ],
    "unread_count": 5
  }
}
```

---

## 📝 Примечания для Backend разработчика

### Обязательные требования:
1. **Snake_case для JSON ключей** - все ключи в snake_case (first_name, not firstName)
2. **ISO 8601 для дат** - все даты в формате ISO 8601 UTC
3. **Bearer Token** - JWT токены для аутентификации
4. **Pagination** - для списков использовать пагинацию
5. **Soft Delete** - удаление сотрудников через изменение статуса

### Валидация:
- Email: стандартный формат email
- Phone: международный формат с +
- Dates: start_time < end_time для смен
- Password: минимум 6 символов

### Статусы:
```dart
// Employee
enum EmployeeStatus { active, inactive, on_leave }

// Shift
enum ShiftStatus { scheduled, in_progress, completed, cancelled }

// User Role
enum UserRole { admin, manager, employee }
```

### Permissions:
- **admin**: полный доступ
- **manager**: CRUD сотрудников и смен
- **employee**: только просмотр своих смен

### Rate Limiting:
- 100 запросов в минуту на IP
- 1000 запросов в час на пользователя

### CORS:
Разрешить запросы с:
- `http://localhost:*` (development)
- `https://app.example.com` (production)

---

**Версия контракта**: 1.0.0  
**Дата последнего обновления**: 2025-11-28  
**Контакт**: frontend@example.com