-- =====================================================================
--  BANCO DE DADOS DO PAINEL DA YUKIE
--  Onde colar: Supabase > seu projeto > SQL Editor > New query.
--  Cole o arquivo inteiro e clique em "Run".
--  Pode rodar de novo sem medo: nada é apagado e nada é duplicado.
--  As abas Tarefas, Ideias, Radar e Links úteis ficam em banco-novas-abas.sql.
--  O tipo "Particular" do calendário fica em banco-calendario-particular.sql.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1) QUEM É A DONA
-- Uma função pequena que responde "sim" só quando quem está logada
-- é você (pelo seu e-mail). Todas as trancas abaixo usam ela.
-- Mesmo que alguém consiga criar uma conta no seu Supabase,
-- essa pessoa NÃO enxerga nada, porque o e-mail dela não é o seu.
-- ---------------------------------------------------------------------
create or replace function public.e_a_dona()
returns boolean
language sql
stable
set search_path = ''
as $$
  select coalesce(auth.jwt() ->> 'email', '') = 'ayyahiro@gmail.com';
$$;


-- ---------------------------------------------------------------------
-- 2) AS TABELAS
-- ---------------------------------------------------------------------

-- VÍDEOS: o que aparece na galeria e nos destaques do portfólio.
-- "destaque" é o número forte do card (ex: 2,4M views).
-- Vídeos com destaque preenchido viram os 3 cards grandes do site.
create table if not exists public.videos (
  id         uuid primary key default gen_random_uuid(),
  titulo     text not null,
  link       text,
  nicho      text,
  formato    text,
  marca      text,
  destaque   text,
  ordem      integer not null default 0,
  visivel    boolean not null default true,
  criado_em  timestamptz not null default now()
);

-- MARCAS: a sua base de contatos de empresa.
-- O formulário do site entra aqui sozinho, como "lead".
create table if not exists public.marcas (
  id              uuid primary key default gen_random_uuid(),
  nome            text not null,
  instagram       text,
  email           text,
  telefone        text,
  situacao        text not null default 'lead'
                  check (situacao in ('lead', 'conversando', 'cliente', 'parada')),
  obs             text,
  ultimo_contato  date,
  criado_em       timestamptz not null default now()
);

-- CALENDÁRIO: o que você vai gravar, editar ou postar em cada dia.
create table if not exists public.calendario (
  id         uuid primary key default gen_random_uuid(),
  titulo     text not null,
  marca      text,
  tipo       text not null default 'gravar'
             check (tipo in ('gravar', 'editar', 'postar', 'particular')),
  data       date not null,
  status     text not null default 'a fazer'
             check (status in ('a fazer', 'feito')),
  criado_em  timestamptz not null default now()
);

-- CAMPANHAS: os seus trabalhos fechados com marcas.
-- O "prazo" daqui aparece sozinho no calendário do painel.
create table if not exists public.campanhas (
  id         uuid primary key default gen_random_uuid(),
  campanha   text not null,
  cliente    text,
  tipo       text not null default 'Conteúdo'
             check (tipo in ('Conteúdo', 'Publicidade')),
  status     text not null default 'Briefing'
             check (status in ('Briefing', 'Roteiro', 'Aprovação Roteiro', 'Gravação', 'Edição', 'Aprovado', 'Entregue')),
  qtd        integer not null default 1 check (qtd >= 0),
  valor      numeric(12, 2) not null default 0 check (valor >= 0),
  prazo      date,
  pagamento  text not null default 'pendente'
             check (pagamento in ('pendente', 'pago')),
  ativa      boolean not null default true,
  favorita   boolean not null default false,
  criado_em  timestamptz not null default now()
);

-- MARCADOS: o que você já marcou no checklist.
-- Cada item do checklist tem uma "chave" de texto (ex: checklist:capa:0).
create table if not exists public.marcados (
  chave          text primary key,
  marcado        boolean not null default true,
  atualizado_em  timestamptz not null default now()
);

-- VISITAS: uma linha por visita ao portfólio, pras métricas do painel.
-- Guarda só a data, a página e de onde a pessoa veio. Nada pessoal.
create table if not exists public.visitas (
  id      uuid primary key default gen_random_uuid(),
  data    timestamptz not null default now(),
  pagina  text,
  origem  text
);

-- Atualização: o calendário aceita também o tipo "particular"
-- (vale pra quem já tinha criado a tabela antes dessa mudança).
alter table public.calendario drop constraint if exists calendario_tipo_check;
alter table public.calendario add constraint calendario_tipo_check
  check (tipo in ('gravar', 'editar', 'postar', 'particular'));

create index if not exists visitas_data_idx on public.visitas (data desc);
create index if not exists videos_ordem_idx on public.videos (ordem);


-- ---------------------------------------------------------------------
-- 3) A TRANCA (RLS) LIGADA EM TODAS AS TABELAS
-- Com o RLS ligado, o banco começa fechado pra todo mundo.
-- Só entra quem tiver uma regra (policy) liberando, uma por uma, abaixo.
-- ---------------------------------------------------------------------
alter table public.videos      enable row level security;
alter table public.marcas      enable row level security;
alter table public.calendario  enable row level security;
alter table public.campanhas   enable row level security;
alter table public.marcados    enable row level security;
alter table public.visitas     enable row level security;


-- ---------------------------------------------------------------------
-- 4) REGRA PRINCIPAL: SÓ VOCÊ, LOGADA, LÊ E ESCREVE TUDO
-- Uma regra por tabela. "for all" quer dizer ler, criar, editar e apagar.
-- ---------------------------------------------------------------------
drop policy if exists "dona faz tudo" on public.videos;
create policy "dona faz tudo" on public.videos
  for all to authenticated
  using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona faz tudo" on public.marcas;
create policy "dona faz tudo" on public.marcas
  for all to authenticated
  using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona faz tudo" on public.calendario;
create policy "dona faz tudo" on public.calendario
  for all to authenticated
  using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona faz tudo" on public.campanhas;
create policy "dona faz tudo" on public.campanhas
  for all to authenticated
  using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona faz tudo" on public.marcados;
create policy "dona faz tudo" on public.marcados
  for all to authenticated
  using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona faz tudo" on public.visitas;
create policy "dona faz tudo" on public.visitas
  for all to authenticated
  using (public.e_a_dona()) with check (public.e_a_dona());


-- ---------------------------------------------------------------------
-- 5) EXCEÇÃO 1: O FORMULÁRIO DO SITE PODE CRIAR UMA MARCA
-- Qualquer pessoa pode INSERIR, mas só como "lead" e com textos de
-- tamanho normal (evita alguém mandar um livro inteiro).
-- Ela NÃO consegue ler, editar nem apagar nada depois.
-- ---------------------------------------------------------------------
drop policy if exists "site cria lead" on public.marcas;
create policy "site cria lead" on public.marcas
  for insert to anon, authenticated
  with check (
    situacao = 'lead'
    and char_length(nome) between 1 and 120
    and char_length(coalesce(email, '')) <= 160
    and char_length(coalesce(instagram, '')) <= 80
    and char_length(coalesce(telefone, '')) <= 40
    and char_length(coalesce(obs, '')) <= 3000
  );


-- ---------------------------------------------------------------------
-- 6) EXCEÇÃO 2: O SITE PODE REGISTRAR UMA VISITA
-- Qualquer pessoa pode INSERIR uma visita. Ler, só você.
-- ---------------------------------------------------------------------
drop policy if exists "site registra visita" on public.visitas;
create policy "site registra visita" on public.visitas
  for insert to anon, authenticated
  with check (
    char_length(coalesce(pagina, '')) <= 200
    and char_length(coalesce(origem, '')) <= 120
  );


-- ---------------------------------------------------------------------
-- 7) EXCEÇÃO NECESSÁRIA: O SITE PRECISA MOSTRAR OS SEUS VÍDEOS
-- Sem esta regra, o portfólio não teria como exibir a galeria pra quem
-- visita. Por isso quem visita pode LER, mas SÓ os vídeos marcados como
-- visíveis. Vídeo escondido (olhinho fechado no painel) continua só seu.
-- ---------------------------------------------------------------------
drop policy if exists "site le videos visiveis" on public.videos;
create policy "site le videos visiveis" on public.videos
  for select to anon
  using (visivel = true);


-- ---------------------------------------------------------------------
-- 8) PERMISSÕES DE BASE
-- Primeiro tira tudo de quem não está logado, depois devolve só o
-- mínimo: inserir marca, inserir visita e ler vídeo. As regras acima
-- continuam valendo por cima disso (a tranca é dupla).
-- ---------------------------------------------------------------------
revoke all on public.videos, public.marcas, public.calendario,
              public.campanhas, public.marcados, public.visitas from anon;

grant insert on public.marcas  to anon;
grant insert on public.visitas to anon;
grant select on public.videos  to anon;

grant select, insert, update, delete on public.videos, public.marcas,
      public.calendario, public.campanhas, public.marcados, public.visitas
  to authenticated;

grant execute on function public.e_a_dona() to anon, authenticated;


-- ---------------------------------------------------------------------
-- 9) UMA LINHA DE EXEMPLO EM CADA LISTA
-- Só entra se a tabela estiver vazia. Todas começam com "EXEMPLO" pra
-- você reconhecer e apagar pelo painel depois.
-- O vídeo de exemplo começa ESCONDIDO, pra não aparecer no seu site.
-- Visitas e checklist começam zerados de verdade.
-- ---------------------------------------------------------------------
insert into public.videos (titulo, link, nicho, formato, marca, destaque, ordem, visivel)
select 'EXEMPLO · Rotina de skincare da manhã', 'https://www.tiktok.com/@yukieyahiro',
       'Skincare', 'Vídeo 9:16', 'Marca de exemplo', '0 views', 1, false
where not exists (select 1 from public.videos);

insert into public.marcas (nome, instagram, email, telefone, situacao, obs, ultimo_contato)
select 'EXEMPLO · Marca de exemplo', '@marcadeexemplo', 'contato@exemplo.com', '',
       'lead', 'Linha de exemplo. Pode apagar.', current_date
where not exists (select 1 from public.marcas);

insert into public.calendario (titulo, marca, tipo, data, status)
select 'EXEMPLO · Gravar vídeo de teste', 'Marca de exemplo', 'gravar', current_date + 2, 'a fazer'
where not exists (select 1 from public.calendario);

insert into public.campanhas (campanha, cliente, tipo, status, qtd, valor, prazo, pagamento, ativa, favorita)
select 'EXEMPLO · Campanha de teste', 'Marca de exemplo', 'Conteúdo', 'Briefing', 1, 0,
       current_date + 5, 'pendente', true, false
where not exists (select 1 from public.campanhas);


-- =====================================================================
--  TESTE DA TRANCA (opcional)
--  Depois de rodar tudo acima, abra uma query nova (New query), cole SÓ
--  um dos testes abaixo, tire os dois tracinhos do começo de cada linha
--  e clique em Run. Eles fingem ser um visitante qualquer, sem login,
--  e desfazem tudo no final (rollback), então não sujam nada.
--
--  TESTE A: visitante tentando ler a sua base de marcas
--  begin; set local role anon; select * from public.marcas; rollback;
--  Resultado certo: erro "permission denied for table marcas".
--  Erro aqui é BOM: quer dizer que a porta está trancada.
--
--  TESTE B: visitante lendo os vídeos
--  begin; set local role anon; select titulo, visivel from public.videos; rollback;
--  Resultado certo: só aparecem vídeos com visivel = true. O vídeo de
--  exemplo está escondido, então no começo a lista vem vazia.
--
--  TESTE C: visitante mandando o formulário
--  begin; set local role anon;
--  insert into public.marcas (nome, situacao) values ('Teste de visitante', 'lead');
--  rollback;
--  Resultado certo: "Success". Se trocar 'lead' por 'cliente', dá erro.
-- =====================================================================
