# Avatar Implementation Guide

## Overview
Employee avatars are displayed throughout the application, including in the schedule view timeline. The current implementation uses randomuser.me for mock data but is designed to be backend-ready.

## Frontend Implementation

### Data Flow
1. Employee model includes `avatarUrl` field (optional String)
2. Schedule view uses `employee.avatarUrl` to display avatars in calendar resources
3. Profile view uses `employee.avatarUrl` to display avatar in header

### Current Mock Implementation
```dart
// Mock API Service generates avatars based on gender
final avatarUrl = isMale
    ? 'https://randomuser.me/api/portraits/men/$genderVariant.jpg'
    : 'https://randomuser.me/api/portraits/women/$genderVariant.jpg';
```

## Backend Requirements

### Employee Model (JSON)
```json
{
  "id": "emp_123",
  "first_name": "Иван",
  "last_name": "Иванов",
  "position": "Менеджер",
  "branch": "ТЦ Мега",
  "status": "active",
  "hire_date": "2023-01-15T00:00:00Z",
  "avatar_url": "https://api.yourcompany.com/avatars/emp_123.jpg",
  "email": "ivan.ivanov@company.com",
  "phone": "+7 (900) 123-45-67"
}
```

### Avatar URL Field
- **Field name**: `avatar_url` (snake_case in JSON)
- **Type**: String (nullable/optional)
- **Format**: Full URL to avatar image
- **Recommended size**: 150x150px minimum for optimal display
- **Supported formats**: JPG, PNG, WebP
- **Default behavior**: If `avatar_url` is null, app displays default avatar icon

### Avatar Storage Options

#### Option 1: Self-hosted Storage
```
https://api.yourcompany.com/avatars/{employee_id}.jpg
```
- Store avatars on company CDN/storage
- Generate presigned URLs for secure access
- Implement image optimization (resize, compress)

#### Option 2: Cloud Storage (S3, GCS, Azure Blob)
```
https://your-bucket.s3.amazonaws.com/avatars/emp_123.jpg
```
- Use cloud storage provider
- Generate presigned URLs with expiration
- Enable CDN for faster delivery

#### Option 3: Third-party Avatar Service
```
https://avatar-service.com/v1/employee/{hash}
```
- Use services like Gravatar, UI Avatars
- Generate based on email or name
- Automatic fallback to initials

### API Endpoints

#### Upload Employee Avatar
```
POST /api/employees/{employee_id}/avatar
Content-Type: multipart/form-data

Request:
- file: Binary image data

Response:
{
  "avatar_url": "https://api.yourcompany.com/avatars/emp_123.jpg",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

#### Delete Employee Avatar
```
DELETE /api/employees/{employee_id}/avatar

Response:
{
  "success": true,
  "avatar_url": null
}
```

### Image Requirements
- **Max file size**: 5MB
- **Allowed formats**: JPEG, PNG, WebP
- **Recommended dimensions**: 150x150px to 500x500px
- **Aspect ratio**: Square (1:1) preferred
- **Processing**: Auto-resize and optimize on upload

### Caching Strategy
- Frontend caches avatar URLs in memory during session
- Browser caches images with appropriate Cache-Control headers
- Recommended cache duration: 24 hours
- Use ETags for cache validation

### Error Handling
- If `avatar_url` is null/empty: Show default icon
- If image fails to load: Show default icon with retry logic
- If upload fails: Show error message, keep previous avatar

## Frontend Code Examples

### Schedule View Resource with Avatar
```dart
final resources = _employees.map((e) {
  return CalendarResource(
    id: e.id,
    displayName: e.fullName,
    color: Colors.blue,
    image: e.avatarUrl != null ? NetworkImage(e.avatarUrl!) : null,
  );
}).toList();
```

### Profile View Avatar Display
```dart
CircleAvatar(
  radius: 50,
  backgroundColor: theme.colorScheme.primary,
  child: ClipOval(
    child: Image.network(
      profile.avatarUrl,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.person,
          size: 50,
          color: theme.colorScheme.onPrimary,
        );
      },
    ),
  ),
)
```

## Migration from Mock to Production

1. **Update API Service**: Replace mock URLs with real API calls
2. **Test with real data**: Verify avatar loading from backend
3. **Handle missing avatars**: Ensure graceful fallback to default icon
4. **Monitor performance**: Check image loading times
5. **Optimize caching**: Implement appropriate cache headers

## Testing Checklist

- [ ] Avatars display correctly in schedule timeline
- [ ] Avatars display correctly in employee profile
- [ ] Avatars display correctly in employee list
- [ ] Default icon shows when avatar_url is null
- [ ] Error handling works when image fails to load
- [ ] Avatar upload works correctly
- [ ] Avatar deletion works correctly
- [ ] Image caching works as expected
- [ ] Performance is acceptable with 50+ employees

## Security Considerations

- Validate file types on upload
- Scan uploaded images for malware
- Limit file size to prevent DoS
- Use presigned URLs with expiration for private avatars
- Implement rate limiting on upload endpoint
- Store avatars in separate storage from sensitive data
