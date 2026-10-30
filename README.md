# Agent Feedback

A two-minute weekly check-in for the Executive Director about her scheduling assistant. One static page on Vercel, answers in Supabase.

## How it works
- `index.html` is the whole app (no build step). Link: `https://<your-vercel-url>/?k=<token>`.
- The page rates the current week (Monday of the week, Los Angeles time). Add `&w=YYYY-MM-DD` for another week.
- Answers autosave as she goes; "Send my answers" marks the week submitted, and she can resend until she is done.
- Tables `agent_feedback_access` (one token per respondent) and `agent_feedback` (one row per respondent per week) have RLS on and no policies. The page only calls `get_agent_feedback` and `save_agent_feedback`.

## Set up
1. Run `supabase/migrations/001_agent_feedback.sql` in your Supabase project.
2. Create a respondent and copy the token: `insert into public.agent_feedback_access (respondent) values ('Name') returning token;`
3. Set `SB_URL` and `SB_KEY` (the publishable key) near the top of the script in `index.html`.
4. Deploy: import this repo in Vercel, or run `vercel` in this folder.

## Read the answers
`supabase/analysis.sql` has four read-only queries: weekly trend, what goes wrong, what she would trust next, and her own words. Pair it with the agent's outcome log (sent as written, edited, discarded): the log says what happened, this says why.

The token is the only secret. Never commit it.
