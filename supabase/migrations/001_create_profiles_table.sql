-- Таблица профилей пользователей (расширенная версия)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  first_name text,
  last_name text,
  role text not null default 'employee',
  status text not null default 'pending',
  full_name text generated always as (
    case
      when first_name is not null and last_name is not null
        then first_name || ' ' || last_name
      when first_name is not null then first_name
      when last_name is not null then last_name
      else 'User'
    end
  ) stored,
  created_at timestamp with time zone default now() not null,
  last_login timestamp with time zone,
  updated_at timestamp with time zone default now() not null,
  constraint role_check check (role in ('employee', 'manager')),
  constraint status_check check (status in ('active', 'inactive', 'pending'))
);

-- Индексы для производительности
create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_profiles_status on public.profiles(status);
create index if not exists idx_profiles_email on public.profiles(email);

-- Комментарии для документации
comment on table public.profiles is 'User profiles with role-based access control';
comment on column public.profiles.role is 'User role: employee or manager';
comment on column public.profiles.status is 'Account status: active, inactive, or pending (awaiting approval)';
