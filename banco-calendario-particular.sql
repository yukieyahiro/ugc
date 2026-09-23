-- =====================================================================
--  CALENDÁRIO: NOVO TIPO "PARTICULAR"
--  Onde colar: Supabase > SQL Editor > New query. Cole tudo e clique em Run.
--  Não apaga nada. Só amplia a lista de tipos aceitos no calendário.
--  Pode rodar de novo sem medo.
-- =====================================================================

-- Tira a regra antiga (que só aceitava gravar, editar e postar)...
alter table public.calendario drop constraint if exists calendario_tipo_check;

-- ...e coloca a nova, que aceita também "particular".
alter table public.calendario add constraint calendario_tipo_check
  check (tipo in ('gravar', 'editar', 'postar', 'particular'));
