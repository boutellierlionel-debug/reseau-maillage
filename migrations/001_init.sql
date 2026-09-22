-- ============================================================================
--  Le Maillage — schéma initial
--  À coller tel quel dans Supabase Studio → SQL Editor → Run.
--  Idempotent : réexécutable sans casser ce qui existe déjà.
-- ============================================================================

-- ---------------------------------------------------------------------------
--  1. Qui a le droit d'entrer
--     Personne ne devient membre sans figurer ici. Un inconnu qui obtient un
--     lien magique sera authentifié mais n'aura aucune fiche, donc aucun accès.
-- ---------------------------------------------------------------------------
create table if not exists public.invites (
  email       text primary key,
  profil      text not null default 'metier' check (profil in ('conseil','metier','anim')),
  region      text not null default 'aura',
  invite_le   timestamptz not null default now()
);

comment on table public.invites is
  'Liste blanche des adresses autorisées. Y ajouter une ligne AVANT d''inviter quelqu''un.';

-- L'animateur. Remplacez l'adresse si ce n'est pas la bonne.
insert into public.invites (email, profil, region)
values ('boutellier.lionel@gmail.com', 'anim', 'aura')
on conflict (email) do nothing;

-- ---------------------------------------------------------------------------
--  2. Les membres
--     Une ligne par personne, créée automatiquement à la première connexion
--     si et seulement si l'adresse est invitée.
-- ---------------------------------------------------------------------------
create table if not exists public.membres (
  id        uuid primary key references auth.users (id) on delete cascade,
  nom       text not null default '',
  metier    text not null default '',
  region    text not null default 'aura',
  profil    text not null default 'metier' check (profil in ('conseil','metier','anim')),
  cree_le   timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
--  3. Le fil : messages et réponses
-- ---------------------------------------------------------------------------
create table if not exists public.messages (
  id        uuid primary key default gen_random_uuid(),
  auteur    uuid not null references public.membres (id) on delete cascade,
  type      text not null check (type in ('question','partage')),
  texte     text not null check (length(trim(texte)) > 2),
  cree_le   timestamptz not null default now()
);
create index if not exists messages_cree_le_idx on public.messages (cree_le desc);
create index if not exists messages_auteur_idx  on public.messages (auteur);

create table if not exists public.reponses (
  id        uuid primary key default gen_random_uuid(),
  message   uuid not null references public.messages (id) on delete cascade,
  auteur    uuid not null references public.membres (id) on delete cascade,
  texte     text not null check (length(trim(texte)) > 1),
  cree_le   timestamptz not null default now()
);
create index if not exists reponses_message_idx on public.reponses (message, cree_le);

-- Le bouton « Utile » : une voix par personne et par message.
create table if not exists public.utiles (
  message   uuid not null references public.messages (id) on delete cascade,
  membre    uuid not null references public.membres (id) on delete cascade,
  primary key (message, membre)
);

-- ---------------------------------------------------------------------------
--  4. L'agenda
-- ---------------------------------------------------------------------------
create table if not exists public.evenements (
  id        uuid primary key default gen_random_uuid(),
  titre     text not null,
  le_jour   date not null,
  horaire   text not null default '',
  lieu      text not null default '',
  visio     boolean not null default false,
  places    int not null default 0,
  cree_par  uuid references public.membres (id) on delete set null,
  cree_le   timestamptz not null default now()
);
create index if not exists evenements_jour_idx on public.evenements (le_jour);

create table if not exists public.inscriptions (
  evenement uuid not null references public.evenements (id) on delete cascade,
  membre    uuid not null references public.membres (id) on delete cascade,
  primary key (evenement, membre)
);

-- ---------------------------------------------------------------------------
--  5. Création automatique de la fiche membre à la première connexion
-- ---------------------------------------------------------------------------
create or replace function public.accueillir_nouveau_membre()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  invitation public.invites%rowtype;
begin
  select * into invitation from public.invites where lower(email) = lower(new.email);
  if not found then
    -- Adresse non invitée : aucun membre créé, donc aucun accès aux données.
    return new;
  end if;

  insert into public.membres (id, nom, metier, region, profil)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nom', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data ->> 'metier', ''),
    invitation.region,
    invitation.profil
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists au_premier_login on auth.users;
create trigger au_premier_login
  after insert on auth.users
  for each row execute function public.accueillir_nouveau_membre();

-- ---------------------------------------------------------------------------
--  6. Règles d'accès (RLS)
--     Principe : il faut une fiche membre pour lire quoi que ce soit, et on ne
--     peut écrire qu'en son propre nom.
-- ---------------------------------------------------------------------------
create or replace function public.est_membre()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.membres where id = auth.uid());
$$;

alter table public.membres      enable row level security;
alter table public.messages     enable row level security;
alter table public.reponses     enable row level security;
alter table public.utiles       enable row level security;
alter table public.evenements   enable row level security;
alter table public.inscriptions enable row level security;
alter table public.invites      enable row level security;

-- membres : tout le monde du groupe se voit ; chacun ne modifie que sa fiche.
drop policy if exists membres_lecture on public.membres;
create policy membres_lecture on public.membres
  for select to authenticated using (public.est_membre());

drop policy if exists membres_maj on public.membres;
create policy membres_maj on public.membres
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- messages
drop policy if exists messages_lecture on public.messages;
create policy messages_lecture on public.messages
  for select to authenticated using (public.est_membre());

drop policy if exists messages_ecriture on public.messages;
create policy messages_ecriture on public.messages
  for insert to authenticated with check (auteur = auth.uid() and public.est_membre());

drop policy if exists messages_maj on public.messages;
create policy messages_maj on public.messages
  for update to authenticated using (auteur = auth.uid()) with check (auteur = auth.uid());

drop policy if exists messages_suppression on public.messages;
create policy messages_suppression on public.messages
  for delete to authenticated using (auteur = auth.uid());

-- réponses
drop policy if exists reponses_lecture on public.reponses;
create policy reponses_lecture on public.reponses
  for select to authenticated using (public.est_membre());

drop policy if exists reponses_ecriture on public.reponses;
create policy reponses_ecriture on public.reponses
  for insert to authenticated with check (auteur = auth.uid() and public.est_membre());

drop policy if exists reponses_suppression on public.reponses;
create policy reponses_suppression on public.reponses
  for delete to authenticated using (auteur = auth.uid());

-- utiles
drop policy if exists utiles_lecture on public.utiles;
create policy utiles_lecture on public.utiles
  for select to authenticated using (public.est_membre());

drop policy if exists utiles_ecriture on public.utiles;
create policy utiles_ecriture on public.utiles
  for insert to authenticated with check (membre = auth.uid());

drop policy if exists utiles_retrait on public.utiles;
create policy utiles_retrait on public.utiles
  for delete to authenticated using (membre = auth.uid());

-- agenda : lecture pour tous les membres, création réservée à l'animation.
drop policy if exists evenements_lecture on public.evenements;
create policy evenements_lecture on public.evenements
  for select to authenticated using (public.est_membre());

drop policy if exists evenements_ecriture on public.evenements;
create policy evenements_ecriture on public.evenements
  for insert to authenticated
  with check (exists (select 1 from public.membres where id = auth.uid() and profil = 'anim'));

drop policy if exists evenements_maj on public.evenements;
create policy evenements_maj on public.evenements
  for update to authenticated
  using (exists (select 1 from public.membres where id = auth.uid() and profil = 'anim'));

drop policy if exists inscriptions_lecture on public.inscriptions;
create policy inscriptions_lecture on public.inscriptions
  for select to authenticated using (public.est_membre());

drop policy if exists inscriptions_ecriture on public.inscriptions;
create policy inscriptions_ecriture on public.inscriptions
  for insert to authenticated with check (membre = auth.uid());

drop policy if exists inscriptions_retrait on public.inscriptions;
create policy inscriptions_retrait on public.inscriptions
  for delete to authenticated using (membre = auth.uid());

-- invites : seule l'animation voit et gère la liste blanche.
drop policy if exists invites_animation on public.invites;
create policy invites_animation on public.invites
  for all to authenticated
  using (exists (select 1 from public.membres where id = auth.uid() and profil = 'anim'))
  with check (exists (select 1 from public.membres where id = auth.uid() and profil = 'anim'));

-- ---------------------------------------------------------------------------
--  7. Temps réel : le fil se met à jour sans recharger
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'reponses'
  ) then
    alter publication supabase_realtime add table public.reponses;
  end if;
end $$;
