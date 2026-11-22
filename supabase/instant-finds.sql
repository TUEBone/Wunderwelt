-- Wandersteine: Fundmeldungen sofort veröffentlichen.
-- Bestehende Fundmeldungen werden ebenfalls sichtbar.
-- Vor öffentlichem Launch zusätzlich CAPTCHA, Rate-Limits und Meldefunktion einrichten.
create or replace function public.report_stone_find(
 p_stone_id text,p_found_on date,p_location_label text,p_photo_path text,
 p_story text,p_latitude numeric,p_longitude numeric
) returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
 if not exists(select 1 from public.stones where id=p_stone_id and status='active') then raise exception 'Stein nicht gefunden'; end if;
 if p_found_on is null or p_found_on>current_date then raise exception 'Ungültiges Funddatum'; end if;
 if length(coalesce(p_location_label,''))>180 or length(coalesce(p_story,''))>2000 then raise exception 'Text zu lang'; end if;
 if (p_latitude is null) <> (p_longitude is null) then raise exception 'Beide Koordinaten erforderlich'; end if;
 if p_latitude is not null and (p_latitude not between -90 and 90 or p_longitude not between -180 and 180) then raise exception 'Ungültige Koordinaten'; end if;
 if p_photo_path is not null then
  if p_photo_path !~ '^finds/[a-f0-9-]{36}[.](jpg|jpeg|png|webp)$' or not exists(select 1 from storage.objects where bucket_id='wandersteine' and name=p_photo_path) then raise exception 'Ungültiger Fotopfad'; end if;
 end if;
 insert into public.stone_finds(stone_id,found_on,location_label,photo_path,story,latitude,longitude,status)
 values(p_stone_id,p_found_on,p_location_label,p_photo_path,p_story,
 case when p_latitude is null then null else round(p_latitude,2) end,
 case when p_longitude is null then null else round(p_longitude,2) end,'approved')
 returning id into v_id;
 return v_id;
end;$$;
revoke all on function public.report_stone_find(text,date,text,text,text,numeric,numeric) from public;
grant execute on function public.report_stone_find(text,date,text,text,text,numeric,numeric) to anon,authenticated;
update public.stone_finds set status='approved' where status='pending';
