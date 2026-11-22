-- Öffentliche Leserechte für registrierte Steine und freigegebene Funde
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.stones TO anon, authenticated;
GRANT SELECT ON TABLE public.stone_finds TO anon, authenticated;
-- RLS bleibt aktiv: Nur aktive Steine und freigegebene Funde sind sichtbar.
