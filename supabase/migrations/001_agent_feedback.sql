-- Weekly feedback on the scheduling agent. One row per respondent per week.
create table public.agent_feedback_access (
  token text primary key default replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
  respondent text not null,
  created_at timestamptz not null default now()
);

create table public.agent_feedback (
  id bigint generated always as identity primary key,
  token text not null references public.agent_feedback_access(token) on delete cascade,
  week_of date not null,                       -- the Monday of the week being rated
  answers jsonb not null default '{}'::jsonb,
  submitted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (token, week_of)
);

-- RLS on, no policies: the page can only use the two functions below.
alter table public.agent_feedback_access enable row level security;
alter table public.agent_feedback enable row level security;
revoke all on public.agent_feedback_access from anon, authenticated;
revoke all on public.agent_feedback from anon, authenticated;

create or replace function public.get_agent_feedback(p_token text, p_week date)
returns jsonb language sql security definer set search_path = '' as $$
  select case
    when not exists (select 1 from public.agent_feedback_access where token = p_token) then jsonb_build_object('valid', false)
    else jsonb_build_object('valid', true,
      'answers', coalesce((select answers from public.agent_feedback where token = p_token and week_of = p_week), '{}'::jsonb),
      'submitted', coalesce((select submitted_at is not null from public.agent_feedback where token = p_token and week_of = p_week), false))
  end;
$$;

create or replace function public.save_agent_feedback(p_token text, p_week date, p_answers jsonb, p_submit boolean default false)
returns boolean language plpgsql security definer set search_path = '' as $$
begin
  if pg_column_size(p_answers) > 50000 then return false; end if;
  if p_week is null or p_week < current_date - 21 or p_week > current_date + 7 then return false; end if;
  if not exists (select 1 from public.agent_feedback_access where token = p_token) then return false; end if;
  insert into public.agent_feedback (token, week_of, answers, submitted_at)
  values (p_token, p_week, p_answers, case when p_submit then now() end)
  on conflict (token, week_of) do update
    set answers = excluded.answers,
        updated_at = now(),
        submitted_at = case when p_submit then now() else public.agent_feedback.submitted_at end;
  return true;
end $$;

revoke all on function public.get_agent_feedback(text, date) from public;
revoke all on function public.save_agent_feedback(text, date, jsonb, boolean) from public;
grant execute on function public.get_agent_feedback(text, date) to anon;
grant execute on function public.save_agent_feedback(text, date, jsonb, boolean) to anon;
