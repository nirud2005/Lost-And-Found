-- Smart Lost & Found: ตารางประกาศที่ทุกคนเห็นร่วมกัน
-- วิธีใช้: Supabase > SQL Editor > วางทั้งไฟล์นี้ > Run

create table if not exists public.items (
  id         bigint generated always as identity primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  type       text not null check (type in ('lost','found')),
  cat        int  not null,
  title      text not null check (char_length(title) <= 120),
  descr      text not null check (char_length(descr) <= 2000),
  place      text not null,
  lat        double precision,
  lng        double precision,
  d          bigint not null,
  contact    text,
  by_name    text,
  st         text not null default 'open' check (st in ('open','done')),
  img        text check (img is null or char_length(img) <= 300000),
  created_at timestamptz not null default now()
);

create index if not exists items_d_idx on public.items (d desc);

alter table public.items enable row level security;

-- ใครก็อ่านได้ (รวมคนที่ยังไม่ล็อกอิน)
create policy items_select on public.items for select using (true);
-- เฉพาะสมาชิกที่ล็อกอินเท่านั้นที่ประกาศได้ และต้องเป็นเจ้าของแถว
create policy items_insert on public.items for insert to authenticated with check (user_id = auth.uid());
-- แก้ไข/ลบได้เฉพาะประกาศของตัวเอง
create policy items_update on public.items for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy items_delete on public.items for delete to authenticated using (user_id = auth.uid());
