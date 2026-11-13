-- Referencia para un proyecto nuevo. Ejecutar manualmente en el SQL Editor.
-- Si measurements ya existe, revisar primero su esquema y sus políticas.
-- No elimina ni reemplaza tablas, datos o políticas existentes.
create table if not exists public.measurements (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  device_id text not null check (device_id = 'OHM01'),
  resistance_ohm float8 check (resistance_ohm between 0 and 1),
  battery_voltage_v float8 not null check (battery_voltage_v between 0 and 6),
  battery_percent int2 not null check (battery_percent between 0 and 100),
  charging bool not null,
  charge_time_remaining_s int4 check (charge_time_remaining_s >= 0),
  discharge_time_remaining_s int4 check (discharge_time_remaining_s >= 0),
  measurement_enabled bool not null,
  status text not null check (status in ('OK', 'CHARGING', 'LOW_BATTERY', 'OVER_RANGE')),
  constraint times_match_charging check (
    (charging and charge_time_remaining_s is not null and discharge_time_remaining_s is null)
    or (not charging and charge_time_remaining_s is null and discharge_time_remaining_s is not null)
  ),
  constraint coherent_state check (
    (status = 'CHARGING' and charging and not measurement_enabled and resistance_ohm is null)
    or (status = 'LOW_BATTERY' and not charging and not measurement_enabled and resistance_ohm is null)
    or (status = 'OVER_RANGE' and not charging and measurement_enabled and resistance_ohm is null)
    or (status = 'OK' and not charging and measurement_enabled and resistance_ohm is not null)
  )
);

alter table public.measurements enable row level security;
grant usage on schema public to anon;
grant select, insert on public.measurements to anon;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public'
    and tablename = 'measurements' and policyname = 'ohm01_anon_insert') then
    create policy ohm01_anon_insert on public.measurements
      for insert to anon with check (device_id = 'OHM01');
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public'
    and tablename = 'measurements' and policyname = 'ohm01_anon_select') then
    create policy ohm01_anon_select on public.measurements
      for select to anon using (true);
  end if;
end $$;
