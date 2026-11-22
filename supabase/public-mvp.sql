-- Wunderwelt: öffentliche MVP-Funktionen. Im Supabase SQL Editor ausführen.
-- Achtung: öffentliche anonyme Uploads brauchen vor großem Launch zusätzlich CAPTCHA/Rate-Limits.
create extension if not exists pgcrypto;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('wandersteine','wandersteine',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=true,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists "Wandersteine public image read" on storage.objects;
create policy "Wandersteine public image read" on storage.objects for select to anon,authenticated
using(bucket_id='wandersteine');
drop policy if exists "Wandersteine public image upload" on storage.objects;
create policy "Wandersteine public image upload" on storage.objects for insert to anon,authenticated
with check(bucket_id='wandersteine' and (storage.foldername(name))[1] in ('stones','finds') and lower(storage.extension(name)) in ('jpg','jpeg','png','webp') and length(name)<180);
create or replace function public.register_stone(p_id text,p_title text,p_description text,p_photo_path text)
returns void language plpgsql security definer set search_path=''
as $$
begin
 if p_id !~ '^[0-9]{6}$' then raise exception 'Ungültige Steinnummer'; end if;
 if length(trim(coalesce(p_title,''))) not between 1 and 100 then raise exception 'Name erforderlich (max. 100 Zeichen)'; end if;
 if length(coalesce(p_description,''))>2000 then raise exception 'Beschreibung zu lang'; end if;
 if p_photo_path !~ ('^stones/'||p_id||'/[a-f0-9-]{36}\\.(jpg|jpeg|png|webp)$') then raise exception 'Ungültiger Fotopfad'; end if;
 if not exists(select 1 from storage.objects where bucket_id='wandersteine' and name=p_photo_path) then raise exception 'Foto nicht hochgeladen'; end if;
 if exists(select 1 from public.stone_reservations where id=p_id and expires_at>now()) then raise exception 'Nummer ist reserviert'; end if;
 insert into public.stones(id,title,description,photo_path) values(p_id,trim(p_title),p_description,p_photo_path);
end;$$;
create or replace function public.report_stone_find(p_stone_id text,p_found_on date,p_location_label text,p_photo_path text,p_story text)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_id uuid;
begin
 if not exists(select 1 from public.stones where id=p_stone_id and status='active') then raise exception 'Stein nicht gefunden'; end if;
 if p_found_on is null or p_found_on>current_date then raise exception 'Ungültiges Funddatum'; end if;
 if length(coalesce(p_location_label,''))>180 or length(coalesce(p_story,''))>2000 then raise exception 'Text zu lang'; end if;
 if p_photo_path !~ '^finds/[a-f0-9-]{36}\\.(jpg|jpeg|png|webp)$' then raise exception 'Ungültiger Fotopfad'; end if;
 if not exists(select 1 from storage.objects where bucket_id='wandersteine' and name=p_photo_path) then raise exception 'Foto nicht hochgeladen'; end if;
 insert into public.stone_finds(stone_id,found_on,location_label,photo_path,story,status)
 values(p_stone_id,p_found_on,p_location_label,p_photo_path,p_story,'pending') returning id into v_id;
 return v_id;
end;$$;
revoke all on function public.register_stone(text,text,text,text) from public;
revoke all on function public.report_stone_find(text,date,text,text,text) from public;
grant execute on function public.register_stone(text,text,text,text) to anon,authenticated;
grant execute on function public.report_stone_find(text,date,text,text,text) to anon,authenticated;
