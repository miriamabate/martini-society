-- Martini Society · privacy: i numeri di telefono non vengono più salvati
update public.items set data = data - 'phone' where col = 'friends' and data ? 'phone';
