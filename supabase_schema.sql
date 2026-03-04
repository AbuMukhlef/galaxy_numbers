-- ═══════════════════════════════════════════════════════════
-- مجرة الأرقام — Supabase Schema
-- الخطوات:
--   1. افتح مشروعك على supabase.com
--   2. من القائمة الجانبية اختر: SQL Editor
--   3. انسخ هذا الملف كله والصقه
--   4. اضغط زر RUN
-- ═══════════════════════════════════════════════════════════

create extension if not exists "uuid-ossp";

-- users
create table if not exists users (
  id            text        primary key,
  name          text        not null,
  selected_path text        not null default 'multiplication',
  created_at    timestamptz not null default now()
);

-- progress
create table if not exists progress (
  user_id       text    not null references users(id) on delete cascade,
  moon_key      text    not null,
  energy        numeric not null default 0,
  is_unlocked   boolean not null default false,
  is_completed  boolean not null default false,
  current_layer int     not null default 1,
  layer1_done   boolean not null default false,
  layer2_done   boolean not null default false,
  layer3_done   boolean not null default false,
  primary key (user_id, moon_key)
);

-- performance
create table if not exists performance (
  user_id       text    not null references users(id) on delete cascade,
  question_key  text    not null,
  attempts      int     not null default 0,
  correct       int     not null default 0,
  wrong         int     not null default 0,
  avg_time      numeric not null default 0,
  last_seen     timestamptz,
  review_after_n int   not null default 0,
  primary key (user_id, question_key)
);

-- badges
create table if not exists badges (
  user_id    text        not null references users(id) on delete cascade,
  badge_type text        not null,
  earned_at  timestamptz not null default now(),
  user_name  text        not null default '',
  primary key (user_id, badge_type)
);

-- streaks
create table if not exists streaks (
  user_id        text        primary key references users(id) on delete cascade,
  current_streak int         not null default 0,
  best_streak    int         not null default 0,
  last_play_date timestamptz
);

-- Row Level Security
alter table users       enable row level security;
alter table progress    enable row level security;
alter table performance enable row level security;
alter table badges      enable row level security;
alter table streaks     enable row level security;

create policy "allow_all" on users       for all using (true) with check (true);
create policy "allow_all" on progress    for all using (true) with check (true);
create policy "allow_all" on performance for all using (true) with check (true);
create policy "allow_all" on badges      for all using (true) with check (true);
create policy "allow_all" on streaks     for all using (true) with check (true);

-- تحقق من إنشاء الجداول
select table_name from information_schema.tables
where table_schema = 'public'
order by table_name;
