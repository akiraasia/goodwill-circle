-- Week 13 Community Starter Requests and Joinable Needs
--
-- Seeds a compact, art-backed starter feed. These are onboarding/demo prompts,
-- not real user posts. People can join as a helpee or helper and unlock a
-- contact option for the matching helper/helpee group.

ALTER TABLE public.help_requests
  ADD COLUMN IF NOT EXISTS short_description TEXT,
  ADD COLUMN IF NOT EXISTS full_description TEXT,
  ADD COLUMN IF NOT EXISTS tags TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
  ADD COLUMN IF NOT EXISTS difficulty TEXT NOT NULL DEFAULT 'medium',
  ADD COLUMN IF NOT EXISTS estimated_people_who_may_benefit TEXT,
  ADD COLUMN IF NOT EXISTS community_request BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS allow_join_need BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS join_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS helper_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS goodwill_impact_score INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tag_credit_bonus INTEGER NOT NULL DEFAULT 0;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'help_requests_difficulty_check'
  ) THEN
    ALTER TABLE public.help_requests
      ADD CONSTRAINT help_requests_difficulty_check
      CHECK (difficulty IN ('low', 'medium', 'high'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'help_requests_community_counts_check'
  ) THEN
    ALTER TABLE public.help_requests
      ADD CONSTRAINT help_requests_community_counts_check
      CHECK (
        join_count >= 0
        AND helper_count >= 0
        AND goodwill_impact_score BETWEEN 0 AND 100
        AND tag_credit_bonus >= 0
      );
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.calculate_tag_credit_bonus(p_tags TEXT[])
RETURNS INTEGER AS $$
BEGIN
  IF COALESCE(array_length(p_tags, 1), 0) >= 2 THEN
    RETURN 10;
  END IF;

  RETURN 0;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.set_help_request_tag_credit_bonus()
RETURNS trigger AS $$
BEGIN
  NEW.tags := COALESCE(NEW.tags, '{}'::TEXT[]);
  NEW.tag_credit_bonus := public.calculate_tag_credit_bonus(NEW.tags);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_help_request_tag_credit_bonus_trigger ON public.help_requests;
CREATE TRIGGER set_help_request_tag_credit_bonus_trigger
  BEFORE INSERT OR UPDATE OF tags ON public.help_requests
  FOR EACH ROW EXECUTE PROCEDURE public.set_help_request_tag_credit_bonus();

CREATE TABLE IF NOT EXISTS public.community_starter_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL UNIQUE,
  short_description TEXT NOT NULL,
  full_description TEXT NOT NULL,
  category TEXT NOT NULL CHECK (
    category IN (
      'Education',
      'Career',
      'Technology',
      'Health Awareness',
      'Blood Donation Awareness',
      'Volunteering',
      'Environment',
      'Transportation',
      'Food Support',
      'Community Events',
      'Elderly Assistance',
      'Mental Wellbeing',
      'Financial Literacy',
      'Entrepreneurship',
      'Government Services',
      'Skill Development'
    )
  ),
  tags TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
  difficulty TEXT NOT NULL CHECK (difficulty IN ('low', 'medium', 'high')),
  estimated_people_who_may_benefit TEXT NOT NULL,
  community_request BOOLEAN NOT NULL DEFAULT true,
  allow_join_need BOOLEAN NOT NULL DEFAULT true,
  join_count INTEGER NOT NULL DEFAULT 0 CHECK (join_count >= 0),
  helper_count INTEGER NOT NULL DEFAULT 0 CHECK (helper_count >= 0),
  goodwill_impact_score INTEGER NOT NULL DEFAULT 0 CHECK (goodwill_impact_score BETWEEN 0 AND 100),
  tag_credit_bonus INTEGER NOT NULL DEFAULT 0 CHECK (tag_credit_bonus >= 0),
  art_asset_path TEXT,
  contact_options JSONB NOT NULL DEFAULT '[]'::JSONB,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'paused', 'completed')),
  source TEXT NOT NULL DEFAULT 'week13_seed',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.community_starter_requests
  ADD COLUMN IF NOT EXISTS art_asset_path TEXT,
  ADD COLUMN IF NOT EXISTS contact_options JSONB NOT NULL DEFAULT '[]'::JSONB,
  DROP CONSTRAINT IF EXISTS community_starter_requests_join_count_check,
  DROP CONSTRAINT IF EXISTS community_starter_requests_helper_count_check,
  ADD CONSTRAINT community_starter_requests_join_count_check CHECK (join_count >= 0),
  ADD CONSTRAINT community_starter_requests_helper_count_check CHECK (helper_count >= 0);

CREATE INDEX IF NOT EXISTS community_starter_requests_category_idx
  ON public.community_starter_requests (category);

CREATE INDEX IF NOT EXISTS community_starter_requests_tags_idx
  ON public.community_starter_requests USING GIN (tags);

CREATE INDEX IF NOT EXISTS community_starter_requests_joinable_idx
  ON public.community_starter_requests (allow_join_need, status, created_at DESC);

ALTER TABLE public.community_starter_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Community starter requests are viewable by everyone." ON public.community_starter_requests;
CREATE POLICY "Community starter requests are viewable by everyone."
  ON public.community_starter_requests
  FOR SELECT
  USING (true);

REVOKE INSERT, UPDATE, DELETE ON public.community_starter_requests FROM anon, authenticated;
GRANT SELECT ON public.community_starter_requests TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.set_community_starter_request_tag_credit_bonus()
RETURNS trigger AS $$
BEGIN
  NEW.tags := COALESCE(NEW.tags, '{}'::TEXT[]);
  NEW.contact_options := COALESCE(NEW.contact_options, '[]'::JSONB);
  NEW.tag_credit_bonus := public.calculate_tag_credit_bonus(NEW.tags);
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_community_starter_request_tag_credit_bonus_trigger ON public.community_starter_requests;
CREATE TRIGGER set_community_starter_request_tag_credit_bonus_trigger
  BEFORE INSERT OR UPDATE OF tags, contact_options ON public.community_starter_requests
  FOR EACH ROW EXECUTE PROCEDURE public.set_community_starter_request_tag_credit_bonus();

CREATE TABLE IF NOT EXISTS public.community_starter_request_joins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES public.community_starter_requests(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  join_role TEXT NOT NULL DEFAULT 'helpee' CHECK (join_role IN ('helpee', 'helper')),
  contact_choice JSONB,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (request_id, user_id)
);

ALTER TABLE public.community_starter_request_joins
  ADD COLUMN IF NOT EXISTS join_role TEXT NOT NULL DEFAULT 'helpee',
  ADD COLUMN IF NOT EXISTS contact_choice JSONB;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'community_starter_request_joins_role_check'
  ) THEN
    ALTER TABLE public.community_starter_request_joins
      ADD CONSTRAINT community_starter_request_joins_role_check
      CHECK (join_role IN ('helpee', 'helper'));
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS community_starter_request_joins_user_idx
  ON public.community_starter_request_joins (user_id, joined_at DESC);

ALTER TABLE public.community_starter_request_joins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own starter joins." ON public.community_starter_request_joins;
CREATE POLICY "Users can view own starter joins."
  ON public.community_starter_request_joins
  FOR SELECT
  USING (auth.uid() = user_id);

REVOKE ALL ON public.community_starter_request_joins FROM anon, authenticated;
GRANT SELECT ON public.community_starter_request_joins TO authenticated;

CREATE OR REPLACE FUNCTION public.join_community_starter_request(
  p_request_id UUID,
  p_join_role TEXT DEFAULT 'helpee',
  p_contact_choice JSONB DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_inserted BOOLEAN;
  v_role TEXT := COALESCE(NULLIF(p_join_role, ''), 'helpee');
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF v_role NOT IN ('helpee', 'helper') THEN
    RAISE EXCEPTION 'Invalid join role';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.community_starter_requests
    WHERE id = p_request_id
      AND status = 'open'
      AND allow_join_need = true
  ) THEN
    RAISE EXCEPTION 'Community starter request not found';
  END IF;

  INSERT INTO public.community_starter_request_joins (
    request_id,
    user_id,
    join_role,
    contact_choice
  )
  VALUES (p_request_id, auth.uid(), v_role, p_contact_choice)
  ON CONFLICT (request_id, user_id) DO UPDATE SET
    join_role = EXCLUDED.join_role,
    contact_choice = EXCLUDED.contact_choice
  WHERE public.community_starter_request_joins.join_role = EXCLUDED.join_role
    AND public.community_starter_request_joins.contact_choice IS DISTINCT FROM EXCLUDED.contact_choice
  RETURNING (xmax = 0) INTO v_inserted;

  IF COALESCE(v_inserted, false) THEN
    UPDATE public.community_starter_requests
    SET join_count = join_count + CASE WHEN v_role = 'helpee' THEN 1 ELSE 0 END,
        helper_count = helper_count + CASE WHEN v_role = 'helper' THEN 1 ELSE 0 END,
        goodwill_impact_score = LEAST(100, goodwill_impact_score + 1),
        updated_at = now()
    WHERE id = p_request_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

REVOKE ALL ON FUNCTION public.join_community_starter_request(UUID, TEXT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.join_community_starter_request(UUID, TEXT, JSONB) TO authenticated;

DELETE FROM public.community_starter_requests
WHERE source = 'week13_seed'
  AND title NOT IN (
    'How do I get my first internship?',
    'What skills should I learn for AI/ML in 2026?',
    'Can someone review my resume?',
    'How do I prepare for placement interviews?',
    'Which projects should I build for my portfolio?',
    'Can someone explain this topic to me?',
    'Looking for teammates for a hackathon',
    'Which certification is worth doing?',
    'How do I improve my LinkedIn profile?',
    'Need feedback on my startup idea'
  );

INSERT INTO public.community_starter_requests (
  title,
  short_description,
  full_description,
  category,
  tags,
  difficulty,
  estimated_people_who_may_benefit,
  community_request,
  allow_join_need,
  join_count,
  helper_count,
  goodwill_impact_score,
  art_asset_path,
  contact_options
)
SELECT
  item.title,
  item.short_description,
  item.full_description,
  item.category,
  item.tags,
  item.difficulty,
  item.estimated_people_who_may_benefit,
  item.community_request,
  item.allow_join_need,
  item.join_count,
  item.helper_count,
  item.goodwill_impact_score,
  item.art_asset_path,
  item.contact_options
FROM jsonb_to_recordset($week13_requests$
[
  {"title":"How do I get my first internship?","short_description":"Ask seniors and mentors for internship search help.","full_description":"A feed-style starter request for students looking for resume tips, internship portals, referral advice, and first-message examples.","category":"Career","tags":["internship","career","students"],"difficulty":"low","estimated_people_who_may_benefit":"25-150 people","community_request":true,"allow_join_need":true,"join_count":24,"helper_count":6,"goodwill_impact_score":58,"art_asset_path":"art/Screenshot 2026-06-13 160413.png","contact_options":[{"label":"Internship helper group","type":"whatsapp","value":"https://wa.me/919000010001?text=Internship%20guidance","note":"For students who need internship search help."},{"label":"Volunteer mentor desk","type":"mentor","value":"internship-mentors@goodwillcircle.local","note":"For helpers who can review resumes or share openings."}]},
  {"title":"What skills should I learn for AI/ML in 2026?","short_description":"Discuss practical AI/ML learning paths.","full_description":"A joinable discussion for learners comparing Python, math, data projects, model basics, and realistic AI/ML roadmaps.","category":"Technology","tags":["ai","learning","career"],"difficulty":"medium","estimated_people_who_may_benefit":"20-120 people","community_request":true,"allow_join_need":true,"join_count":18,"helper_count":5,"goodwill_impact_score":52,"art_asset_path":"art/Screenshot 2026-06-13 160438.png","contact_options":[{"label":"AI/ML learner circle","type":"group","value":"ai-ml-learners@goodwillcircle.local","note":"Join if you want a roadmap or study partners."},{"label":"AI/ML helper circle","type":"mentor","value":"ai-ml-helpers@goodwillcircle.local","note":"Join if you can suggest projects or resources."}]},
  {"title":"Can someone review my resume?","short_description":"Get friendly feedback before applying.","full_description":"Students and early professionals can upload or describe their resume and get practical feedback from volunteers.","category":"Career","tags":["resume","career"],"difficulty":"low","estimated_people_who_may_benefit":"20-100 people","community_request":true,"allow_join_need":true,"join_count":31,"helper_count":8,"goodwill_impact_score":65,"art_asset_path":"art/Screenshot 2026-06-13 160453.png","contact_options":[{"label":"Resume review queue","type":"group","value":"resume-review@goodwillcircle.local","note":"For people who want resume feedback."},{"label":"Resume reviewer desk","type":"mentor","value":"resume-helpers@goodwillcircle.local","note":"For helpers who can review one or two resumes."}]},
  {"title":"How do I prepare for placement interviews?","short_description":"Practice interview basics with peers and helpers.","full_description":"A shared request for mock introductions, HR questions, basic technical practice, and placement preparation experiences.","category":"Career","tags":["placement","interview"],"difficulty":"medium","estimated_people_who_may_benefit":"30-160 people","community_request":true,"allow_join_need":true,"join_count":29,"helper_count":7,"goodwill_impact_score":61,"art_asset_path":"art/Screenshot 2026-06-13 160548.png","contact_options":[{"label":"Mock interview group","type":"group","value":"placement-practice@goodwillcircle.local","note":"For students who want interview practice."},{"label":"Interview helper panel","type":"mentor","value":"interview-helpers@goodwillcircle.local","note":"For volunteers who can run mock interviews."}]},
  {"title":"Which projects should I build for my portfolio?","short_description":"Compare project ideas for a stronger portfolio.","full_description":"Students can join to discuss project ideas, scope, timelines, and how to present work clearly in a portfolio.","category":"Career","tags":["projects","portfolio"],"difficulty":"medium","estimated_people_who_may_benefit":"15-100 people","community_request":true,"allow_join_need":true,"join_count":17,"helper_count":4,"goodwill_impact_score":44,"art_asset_path":"art/Screenshot 2026-06-13 160629.png","contact_options":[{"label":"Portfolio project circle","type":"group","value":"portfolio-projects@goodwillcircle.local","note":"For learners choosing what to build."},{"label":"Project mentor desk","type":"mentor","value":"project-mentors@goodwillcircle.local","note":"For helpers who can review project ideas."}]},
  {"title":"Can someone explain this topic to me?","short_description":"Ask for simple explanations of difficult topics.","full_description":"A flexible study-help request for students stuck on a topic and helpers who can explain it in plain language.","category":"Education","tags":["education","help"],"difficulty":"medium","estimated_people_who_may_benefit":"20-130 people","community_request":true,"allow_join_need":true,"join_count":21,"helper_count":6,"goodwill_impact_score":56,"art_asset_path":"art/Screenshot 2026-06-13 160644.png","contact_options":[{"label":"Topic help room","type":"group","value":"topic-help@goodwillcircle.local","note":"For students who need a simple explanation."},{"label":"Study helper desk","type":"mentor","value":"study-helpers@goodwillcircle.local","note":"For helpers who can explain subjects."}]},
  {"title":"Looking for teammates for a hackathon","short_description":"Find collaborators for a hackathon team.","full_description":"A joinable prompt for students who need teammates, designers, developers, presenters, or idea partners for a hackathon.","category":"Technology","tags":["hackathon","collaboration"],"difficulty":"medium","estimated_people_who_may_benefit":"10-80 people","community_request":true,"allow_join_need":true,"join_count":13,"helper_count":3,"goodwill_impact_score":39,"art_asset_path":"art/Screenshot 2026-06-13 160708.png","contact_options":[{"label":"Hackathon team finder","type":"group","value":"hackathon-teams@goodwillcircle.local","note":"For people looking for a team."},{"label":"Hackathon mentor corner","type":"mentor","value":"hackathon-mentors@goodwillcircle.local","note":"For helpers who can guide teams."}]},
  {"title":"Which certification is worth doing?","short_description":"Discuss certification choices before spending time or money.","full_description":"A discussion-led request for comparing certificates, free learning paths, and whether a credential fits a career goal.","category":"Skill Development","tags":["certification","career"],"difficulty":"low","estimated_people_who_may_benefit":"15-100 people","community_request":true,"allow_join_need":true,"join_count":16,"helper_count":4,"goodwill_impact_score":42,"art_asset_path":"art/Screenshot 2026-06-13 160726.png","contact_options":[{"label":"Certification discussion room","type":"group","value":"certification-advice@goodwillcircle.local","note":"For learners comparing options."},{"label":"Career advisor desk","type":"mentor","value":"certification-helpers@goodwillcircle.local","note":"For helpers who can share experience."}]},
  {"title":"How do I improve my LinkedIn profile?","short_description":"Get suggestions for LinkedIn basics.","full_description":"A practical request for improving headlines, summaries, project sections, and networking basics on LinkedIn.","category":"Career","tags":["linkedin","networking"],"difficulty":"low","estimated_people_who_may_benefit":"15-90 people","community_request":true,"allow_join_need":true,"join_count":19,"helper_count":5,"goodwill_impact_score":46,"art_asset_path":"art/Screenshot 2026-06-13 160744.png","contact_options":[{"label":"LinkedIn profile cleanup","type":"group","value":"linkedin-cleanup@goodwillcircle.local","note":"For people who want profile feedback."},{"label":"Networking helper desk","type":"mentor","value":"linkedin-helpers@goodwillcircle.local","note":"For helpers who can suggest profile edits."}]},
  {"title":"Need feedback on my startup idea","short_description":"Get early feedback before building too much.","full_description":"Students and early founders can join to discuss the problem, users, solution, and next step for a startup idea.","category":"Entrepreneurship","tags":["startup","entrepreneurship"],"difficulty":"medium","estimated_people_who_may_benefit":"10-70 people","community_request":true,"allow_join_need":true,"join_count":11,"helper_count":3,"goodwill_impact_score":35,"art_asset_path":"art/Screenshot 2026-06-13 160803.png","contact_options":[{"label":"Startup feedback circle","type":"group","value":"startup-feedback@goodwillcircle.local","note":"For founders who want early feedback."},{"label":"Founder helper desk","type":"mentor","value":"startup-helpers@goodwillcircle.local","note":"For helpers who can challenge ideas kindly."}]}
]
$week13_requests$::jsonb) AS item(
  title TEXT,
  short_description TEXT,
  full_description TEXT,
  category TEXT,
  tags TEXT[],
  difficulty TEXT,
  estimated_people_who_may_benefit TEXT,
  community_request BOOLEAN,
  allow_join_need BOOLEAN,
  join_count INTEGER,
  helper_count INTEGER,
  goodwill_impact_score INTEGER,
  art_asset_path TEXT,
  contact_options JSONB
)
ON CONFLICT (title) DO UPDATE SET
  short_description = EXCLUDED.short_description,
  full_description = EXCLUDED.full_description,
  category = EXCLUDED.category,
  tags = EXCLUDED.tags,
  difficulty = EXCLUDED.difficulty,
  estimated_people_who_may_benefit = EXCLUDED.estimated_people_who_may_benefit,
  community_request = EXCLUDED.community_request,
  allow_join_need = EXCLUDED.allow_join_need,
  join_count = EXCLUDED.join_count,
  helper_count = EXCLUDED.helper_count,
  goodwill_impact_score = EXCLUDED.goodwill_impact_score,
  art_asset_path = EXCLUDED.art_asset_path,
  contact_options = EXCLUDED.contact_options,
  source = 'week13_seed',
  updated_at = now();
