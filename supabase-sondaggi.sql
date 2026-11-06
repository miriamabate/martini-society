-- Martini Society: abilita la sezione Sondaggi
-- Supabase → SQL Editor → New query → incolla → Run. Non tocca dati né parola d'ordine.
alter table public.items drop constraint if exists items_col_check;
alter table public.items add constraint items_col_check
  check (col in ('friends','events','places','wishlist','columns','polls','pollvotes'));
