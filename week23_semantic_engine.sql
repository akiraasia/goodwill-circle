-- week23_semantic_engine.sql
-- Extension and Schema for the HGOS Semantic Understanding Engine

-- 1. Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Create the Semantic Storage Table
CREATE TABLE IF NOT EXISTS public.wish_semantics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wish_id UUID REFERENCES public.wishes(id) ON DELETE CASCADE,
    wish_text TEXT NOT NULL,
    embedding vector(768),
    analysis_json JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create Vector Index for Fast Semantic Search
-- Note: 'lists' depends on row count, 100 is a good default for up to ~100k rows
CREATE INDEX IF NOT EXISTS wish_semantics_embedding_idx 
ON public.wish_semantics USING ivfflat (embedding vector_cosine_ops) 
WITH (lists = 100);
