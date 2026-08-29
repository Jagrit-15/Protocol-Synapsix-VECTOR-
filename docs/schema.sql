-- Protocol Synapsix schema (SIH26168). snake_case columns.
-- PLACEHOLDER: apply in Supabase SQL editor. RLS is demo-minimal.

create table trips (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) not null,
  started_at timestamptz not null, ended_at timestamptz,
  distance_m double precision, max_drift_m double precision,
  pct_time_dr double precision, created_at timestamptz default now()
);
create table trajectory_points (
  id bigint generated always as identity primary key,
  trip_id uuid references trips(id) not null, ts timestamptz not null,
  lat double precision, lon double precision,
  source text check (source in ('gnss','fused','dr_only')),
  accuracy_m double precision, covariance_major_m double precision,
  covariance_minor_m double precision, heading_deg double precision
);
create table sensor_calibration (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) not null,
  device_model text, accel_bias jsonb, gyro_bias jsonb,
  calibrated_at timestamptz default now()
);
create table model_versions (
  id bigint generated always as identity primary key,
  model_name text not null, version text not null,
  file_url text not null, metrics jsonb, released_at timestamptz default now()
);
alter table trips enable row level security;
create policy "Users see own trips" on trips for select using (auth.uid() = user_id);
create policy "Users insert own trips" on trips for insert with check (auth.uid() = user_id);
