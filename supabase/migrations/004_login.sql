-- Martini Society · login personale (Supabase Auth) al posto della parola d'ordine condivisa.
-- Possono leggere e scrivere solo gli utenti autenticati la cui email è in private.members
-- (la lista viene scritta dal workflow a partire dal secret CLUB_EMAILS).

create table if not exists private.members (email text primary key);

create or replace function private.jwt_email() returns text
language sql stable set search_path = '' as $$
  select lower(coalesce(nullif(current_setting('request.jwt.claims', true), '')::json ->> 'email', ''));
$$;

create or replace function private.require_member() returns void
language plpgsql stable security definer set search_path = '' as $$
begin
  if coalesce(nullif(current_setting('request.jwt.claims', true), '')::json ->> 'role', '') <> 'authenticated'
     or not exists (select 1 from private.members m where m.email = private.jwt_email()) then
    raise exception 'accesso non autorizzato' using errcode = '42501';
  end if;
end $$;

-- via le vecchie funzioni con la parola d'ordine
drop function if exists public.club_ok(text);
drop function if exists public.ms_list(text);
drop function if exists public.ms_put(text, text, text, jsonb);
drop function if exists public.ms_del(text, text);
drop function if exists private.require_member(text);
drop table if exists private.club;

create or replace function public.me_ok() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce(nullif(current_setting('request.jwt.claims', true), '')::json ->> 'role', '') = 'authenticated'
     and exists (select 1 from private.members m where m.email = private.jwt_email());
$$;

create or replace function public.ms_list()
returns table (id text, col text, data jsonb)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_member();
  return query select i.id, i.col, i.data from public.items i order by i.created_at;
end $$;

create or replace function public.ms_put(p_id text, p_col text, p_data jsonb) returns void
language plpgsql volatile security definer set search_path = '' as $$
begin
  perform private.require_member();
  insert into public.items (id, col, data) values (p_id, p_col, p_data)
  on conflict (id) do update set data = excluded.data, updated_at = now();
end $$;

create or replace function public.ms_del(p_id text) returns void
language plpgsql volatile security definer set search_path = '' as $$
begin
  perform private.require_member();
  delete from public.items where id = p_id;
end $$;

revoke all on function public.me_ok(), public.ms_list(), public.ms_put(text, text, jsonb), public.ms_del(text) from public, anon;
grant execute on function public.me_ok(), public.ms_list(), public.ms_put(text, text, jsonb), public.ms_del(text) to authenticated;
