-- Martini Society: da incollare in Supabase → SQL Editor → Run (prima installazione)
-- PRIMA cambia la parola d'ordine qui sotto (lunga, tipo una frase, senza apostrofi).

create table if not exists public.items (
  id          text primary key,
  col         text not null check (col in ('friends','events','places','wishlist','columns','polls','pollvotes')),
  data        jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- la parola d'ordine sta in uno schema non esposto dalle API
create schema if not exists private;
create table if not exists private.club (secret text not null);
delete from private.club;
insert into private.club values ('cambiami-con-una-frase-lunga-tipo-un-martini-al-tramonto');

-- controllo della parola d'ordine (usato dalla schermata "Solo su invito")
create or replace function public.club_ok(k text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from private.club where secret = coalesce(k, ''));
$$;

create or replace function private.require_member(k text) returns void
language plpgsql stable security definer set search_path = '' as $$
begin
  if not exists (select 1 from private.club where secret = coalesce(k, '')) then
    raise exception 'parola d''ordine non valida' using errcode = '42501';
  end if;
end $$;

-- leggere tutto
create or replace function public.ms_list(k text)
returns table (id text, col text, data jsonb)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_member(k);
  return query select i.id, i.col, i.data from public.items i order by i.created_at;
end $$;

-- creare o aggiornare un elemento
create or replace function public.ms_put(k text, p_id text, p_col text, p_data jsonb) returns void
language plpgsql volatile security definer set search_path = '' as $$
begin
  perform private.require_member(k);
  insert into public.items (id, col, data) values (p_id, p_col, p_data)
  on conflict (id) do update set data = excluded.data, updated_at = now();
end $$;

-- eliminare un elemento
create or replace function public.ms_del(k text, p_id text) returns void
language plpgsql volatile security definer set search_path = '' as $$
begin
  perform private.require_member(k);
  delete from public.items where id = p_id;
end $$;

-- la tabella ora si raggiunge SOLO tramite le funzioni qui sopra
drop policy if exists "solo il club" on public.items;
alter table public.items enable row level security;
revoke all on public.items from anon, authenticated;
drop function if exists public.is_member();

revoke all on function public.club_ok(text), public.ms_list(text),
  public.ms_put(text, text, text, jsonb), public.ms_del(text, text) from public;
grant execute on function public.club_ok(text), public.ms_list(text),
  public.ms_put(text, text, text, jsonb), public.ms_del(text, text) to anon, authenticated;

notify pgrst, 'reload schema';

-- Per cambiare parola d'ordine in futuro:
--   update private.club set secret = 'nuova-frase';
