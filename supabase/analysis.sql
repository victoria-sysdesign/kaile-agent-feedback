-- Run in the Supabase SQL editor (or ask Claude to run it). Read-only.

-- 1. Week by week: how much did it help, and how did drafts go?
select week_of,
       (answers->>'helped')::int as helped_1_to_5,
       answers->>'drafts'        as drafts,
       answers->>'used'          as used,
       submitted_at
from public.agent_feedback
order by week_of;

-- 2. What goes wrong most often (all weeks)
select issue, count(*) as weeks_reported
from public.agent_feedback, jsonb_array_elements_text(answers->'issues') as issue
where issue <> 'nothing'
group by issue order by weeks_reported desc;

-- 3. What she would trust it to do on its own next
select task, count(*) as weeks_requested
from public.agent_feedback, jsonb_array_elements_text(answers->'autonomy') as task
group by task order by weeks_requested desc;

-- 4. Her own words, newest first
select week_of, answers->>'good' as went_well, answers->>'fix' as change_next
from public.agent_feedback
where coalesce(answers->>'good','') <> '' or coalesce(answers->>'fix','') <> ''
order by week_of desc;
