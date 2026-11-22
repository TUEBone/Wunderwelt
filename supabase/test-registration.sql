-- Begrenzte öffentliche Testregistrierung (maximal 20 Steine)
create or replace function public.register_test_stone(
  p_id text, p_title text, p_description text default ''
)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  perform pg_catalog.pg_advisory_xact_lock(8675309);
  if p_id !~ '^9000[0-9]{2}$' then
    raise exception 'Für den Test sind nur Nummern von 900000 bis 900099 erlaubt.';
  end if;
  if length(trim(coalesce(p_title,''))) < 1 or length(p_title) > 100 then
    raise exception 'Bitte einen Namen mit maximal 100 Zeichen eingeben.';
  end if;
  if length(coalesce(p_description,'')) > 2000 then
    raise exception 'Die Beschreibung ist zu lang.';
  end if;
  if (select count(*) from public.stones where id ~ '^9000[0-9]{2}$') >= 20 then
    raise exception 'Das Limit von 20 Teststeinen ist erreicht.';
  end if;
  insert into public.stones(id,title,description,photo_path)
  values (p_id, trim(p_title), coalesce(p_description,''), 'test/platzhalter.jpg');
end;
$$;
revoke all on function public.register_test_stone(text,text,text) from public;
grant execute on function public.register_test_stone(text,text,text) to anon;
