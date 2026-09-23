-- =====================================================================
--  ABA ROTEIROS: biblioteca de transcrições e configurações do painel
--  Onde colar: Supabase > SQL Editor > New query. Cole tudo e clique em Run.
--  Não mexe em nada que já existe. Pode rodar de novo sem medo.
-- =====================================================================


-- 1) QUEM É A DONA (a mesma regra das outras tabelas do painel)
-- Só responde "sim" quando quem está logada é você, pelo seu e-mail.
create or replace function public.e_a_dona()
returns boolean
language sql
stable
set search_path = ''
as $$
  select coalesce(auth.jwt() ->> 'email', '') = 'ayyahiro@gmail.com';
$$;


-- 2) ROTEIROS: cada vídeo transcrito (seu ou de outra creator)
create table if not exists public.roteiros (
  id           uuid primary key default gen_random_uuid(),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  fonte        text not null default 'manual'
               check (fonte in ('instagram', 'tiktok', 'youtube', 'manual')),
  url          text,
  perfil       text,
  de_quem      text not null default 'outra'
               check (de_quem in ('minha', 'outra')),
  titulo       text,
  transcricao  text,
  legenda      text,
  postado_em   date,
  tags         text[] not null default '{}',
  obs          text,
  status       text not null default 'pronto'
               check (status in ('processando', 'pronto', 'falhou')),
  erro         text,
  segmentos    jsonb
);

create index if not exists roteiros_created_at_idx on public.roteiros (created_at desc);


-- 3) CONFIGURAÇÕES: guarda a sua chave da Supadata (e outras no futuro)
-- Fica no banco, e não no código, pra funcionar em qualquer computador.
create table if not exists public.configuracoes (
  chave       text primary key,
  valor       text,
  updated_at  timestamptz not null default now()
);


-- 4) ATUALIZA O "updated_at" SOZINHO A CADA ALTERAÇÃO
create or replace function public.toca_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists roteiros_updated_at on public.roteiros;
create trigger roteiros_updated_at before update on public.roteiros
  for each row execute function public.toca_updated_at();

drop trigger if exists configuracoes_updated_at on public.configuracoes;
create trigger configuracoes_updated_at before update on public.configuracoes
  for each row execute function public.toca_updated_at();


-- 5) A TRANCA (RLS) LIGADA NAS DUAS TABELAS
-- Só você, logada, lê, cria, edita e apaga. Visitante sem login: nada.
alter table public.roteiros      enable row level security;
alter table public.configuracoes enable row level security;

drop policy if exists "dona faz tudo" on public.roteiros;
create policy "dona faz tudo" on public.roteiros
  for all to authenticated
  using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona faz tudo" on public.configuracoes;
create policy "dona faz tudo" on public.configuracoes
  for all to authenticated
  using (public.e_a_dona()) with check (public.e_a_dona());


-- 6) PERMISSÕES: nada pra quem não está logado
revoke all on public.roteiros, public.configuracoes from anon;
grant select, insert, update, delete on public.roteiros, public.configuracoes to authenticated;
