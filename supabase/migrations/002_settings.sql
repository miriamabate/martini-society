-- Martini Society · impostazioni condivise (es. link del gruppo per le chiamate)
alter table public.items drop constraint if exists items_col_check;
alter table public.items add constraint items_col_check
  check (col in ('friends','events','places','wishlist','columns','polls','pollvotes','settings'));
