-- Enable Supabase Realtime so changes sync live across devices.
-- Run once in the Supabase dashboard → SQL Editor. Safe to re-run.

do $$
begin
  begin alter publication supabase_realtime add table public.transactions;    exception when others then null; end;
  begin alter publication supabase_realtime add table public.staff;           exception when others then null; end;
  begin alter publication supabase_realtime add table public.salary_records;  exception when others then null; end;
  begin alter publication supabase_realtime add table public.advance_records; exception when others then null; end;
  begin alter publication supabase_realtime add table public.events;          exception when others then null; end;
end $$;
