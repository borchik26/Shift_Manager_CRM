-- Включить RLS
alter table public.profiles enable row level security;

-- Политика 1: Пользователи могут читать свой профиль
do $$
begin
  if not exists (
    select 1 from pg_policies where policyname = 'Users can read own profile' and tablename = 'profiles'
  ) then
    create policy "Users can read own profile"
      on public.profiles
      for select
      using (auth.uid() = id);
  end if;
end $$;

-- Политика 2: Пользователи могут обновлять свой профиль (кроме role и status)
do $$
begin
  if not exists (
    select 1 from pg_policies where policyname = 'Users can update own profile' and tablename = 'profiles'
  ) then
    create policy "Users can update own profile"
      on public.profiles
      for update
      using (auth.uid() = id)
      with check (auth.uid() = id);
  end if;
end $$;

-- Политика 3: Только менеджеры могут читать профили других пользователей
do $$
begin
  if not exists (
    select 1 from pg_policies where policyname = 'Managers can read all profiles' and tablename = 'profiles'
  ) then
    create policy "Managers can read all profiles"
      on public.profiles
      for select
      using (
        auth.uid() in (
          select id from public.profiles where role = 'manager'
        )
      );
  end if;
end $$;

-- Политика 4: System/Service role может всё (для backend операций)
-- Автоматически применяется при использовании service_role ключа
