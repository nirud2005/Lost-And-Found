-- ============================================================
-- Smart Lost & Found มศว : ตั้งค่า Supabase
-- วางทั้งไฟล์ใน SQL Editor แล้วกด Run (รันซ้ำได้ ไม่เสียข้อมูล)
-- ============================================================

-- 1) ตารางประกาศ (เก็บข้อมูลทั้งประกาศไว้ในคอลัมน์ data แบบ JSON)
create table if not exists public.items (
  id         text primary key,
  type       text not null check (type in ('lost', 'found')),
  status     text not null default 'open' check (status in ('open', 'pending', 'returned')),
  data       jsonb not null check (pg_column_size(data) < 40000),
  created_at timestamptz not null default now()
);

create index if not exists items_created_at_idx on public.items (created_at desc);

-- 2) Row Level Security: ใครก็อ่านได้ ใครก็โพสต์ได้ แก้ได้เฉพาะ "สถานะ" ลบไม่ได้
alter table public.items enable row level security;

drop policy if exists "read items"   on public.items;
drop policy if exists "insert items" on public.items;
drop policy if exists "update status" on public.items;

create policy "read items" on public.items
  for select to anon, authenticated
  using (true);

create policy "insert items" on public.items
  for insert to anon, authenticated
  with check (status = 'open' and char_length(id) <= 64);

create policy "update status" on public.items
  for update to anon, authenticated
  using (true)
  with check (status in ('open', 'pending', 'returned'));

-- จำกัดให้แก้ได้แค่คอลัมน์ status เท่านั้น (ห้ามแก้ชื่อ รูป เบอร์ติดต่อ ฯลฯ)
revoke update on public.items from anon, authenticated;
grant  update (status) on public.items to anon, authenticated;

-- 3) ที่เก็บรูป (bucket สาธารณะ ไฟล์ละไม่เกิน 1 MB เฉพาะรูปภาพ)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('item-images', 'item-images', true, 1048576, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "upload item images" on storage.objects;

create policy "upload item images" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'item-images');
