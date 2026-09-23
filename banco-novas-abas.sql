-- =====================================================================
--  ABAS NOVAS DO PAINEL: Tarefas, Ideias, Radar de novidades e Links úteis
--  Onde colar: Supabase > SQL Editor > New query. Cole tudo e clique em Run.
--  Não mexe em nada que já existe. Pode rodar de novo sem medo.
--  (Precisa do banco.sql já rodado antes, porque usa a função e_a_dona.)
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1) AS TABELAS NOVAS
-- ---------------------------------------------------------------------

-- TAREFAS: a sua lista de afazeres.
create table if not exists public.tarefas (
  id          uuid primary key default gen_random_uuid(),
  titulo      text not null,
  prazo       date,
  prioridade  text not null default 'normal'
              check (prioridade in ('alta', 'normal', 'baixa')),
  feita       boolean not null default false,
  feita_em    timestamptz,
  criado_em   timestamptz not null default now()
);

-- IDEIAS: o quadro de ideias de conteúdo, da ideia até o post.
create table if not exists public.ideias (
  id         uuid primary key default gen_random_uuid(),
  titulo     text not null,
  nicho      text,
  formato    text,
  gancho     text,
  status     text not null default 'ideia'
             check (status in ('ideia', 'roteiro', 'gravado', 'postado')),
  obs        text,
  criado_em  timestamptz not null default now()
);

-- RADAR: novidades que você quer guardar (tendência, áudio, plataforma...).
create table if not exists public.radar (
  id         uuid primary key default gen_random_uuid(),
  titulo     text not null,
  categoria  text not null default 'Tendência'
             check (categoria in ('Tendência', 'Áudio em alta', 'Plataforma', 'Oportunidade', 'Marca', 'Outro')),
  link       text,
  nota       text,
  status     text not null default 'nova'
             check (status in ('nova', 'testar', 'usei', 'arquivada')),
  fixada     boolean not null default false,
  criado_em  timestamptz not null default now()
);

-- LINKS ÚTEIS: os seus links de trabalho, por categoria.
create table if not exists public.links (
  id         uuid primary key default gen_random_uuid(),
  titulo     text not null,
  url        text not null,
  categoria  text not null default 'Ferramentas',
  descricao  text,
  favorito   boolean not null default false,
  criado_em  timestamptz not null default now()
);


-- ---------------------------------------------------------------------
-- 2) A TRANCA (RLS) LIGADA NAS TABELAS NOVAS
-- Aqui não tem exceção nenhuma: só você, logada, lê e escreve.
-- ---------------------------------------------------------------------
alter table public.tarefas enable row level security;
alter table public.ideias  enable row level security;
alter table public.radar   enable row level security;
alter table public.links   enable row level security;

drop policy if exists "dona faz tudo" on public.tarefas;
create policy "dona faz tudo" on public.tarefas
  for all to authenticated
  using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona faz tudo" on public.ideias;
create policy "dona faz tudo" on public.ideias
  for all to authenticated
  using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona faz tudo" on public.radar;
create policy "dona faz tudo" on public.radar
  for all to authenticated
  using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona faz tudo" on public.links;
create policy "dona faz tudo" on public.links
  for all to authenticated
  using (public.e_a_dona()) with check (public.e_a_dona());


-- ---------------------------------------------------------------------
-- 3) PERMISSÕES: visitante sem login não tem acesso nenhum
-- ---------------------------------------------------------------------
revoke all on public.tarefas, public.ideias, public.radar, public.links from anon;

grant select, insert, update, delete on public.tarefas, public.ideias, public.radar, public.links
  to authenticated;


-- ---------------------------------------------------------------------
-- 4) UMA LINHA DE EXEMPLO EM CADA LISTA (só se estiver vazia)
-- ---------------------------------------------------------------------
insert into public.tarefas (titulo, prazo, prioridade)
select 'EXEMPLO · Responder as marcas da semana', current_date, 'normal'
where not exists (select 1 from public.tarefas);

insert into public.ideias (titulo, nicho, formato, gancho, status)
select 'EXEMPLO · Minha rotina de skincare da noite', 'Skincare', 'Rotina com o produto',
       'Escreva aqui a primeira frase do vídeo', 'ideia'
where not exists (select 1 from public.ideias);

insert into public.radar (titulo, categoria, nota, status)
select 'EXEMPLO · Novidade que eu vi hoje', 'Tendência',
       'Anote aqui o que viu, onde viu e como poderia usar.', 'nova'
where not exists (select 1 from public.radar);

insert into public.links (titulo, url, categoria, descricao)
select 'EXEMPLO · Meu portfólio', 'https://yukieyahiro.github.io/ugc/', 'Ferramentas',
       'Linha de exemplo. Pode editar ou apagar.'
where not exists (select 1 from public.links);
