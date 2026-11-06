-- Martini Society: da incollare in Supabase → SQL Editor → Run
-- PRIMA cambia la parola d'ordine qui sotto (lunga, tipo una frase).

create table if not exists public.items (
  id          text primary key,
  col         text not null check (col in ('friends','events','places','wishlist','columns')),
  data        jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- la parola d'ordine sta in uno schema non esposto dalle API
create schema if not exists private;
create table if not exists private.club (secret text not null);
delete from private.club;
insert into private.club values ('cambiami-con-una-frase-lunga-tipo-un-martini-al-tramonto');

-- vero se la richiesta porta l'header x-club-key giusto
create or replace function public.is_member() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from private.club
    where secret = coalesce(current_setting('request.headers', true)::json ->> 'x-club-key', '')
  );
$$;
revoke all on function public.is_member() from public;
grant execute on function public.is_member() to anon, authenticated;

alter table public.items enable row level security;
drop policy if exists "solo il club" on public.items;
create policy "solo il club" on public.items
  for all to anon
  using (public.is_member())
  with check (public.is_member());
grant select, insert, update, delete on public.items to anon;

-- Per cambiare parola d'ordine in futuro:
--   update private.club set secret = 'nuova-frase';
