from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import uuid
import logging

from models import (
    AnalyzeWishRequest, WishAnalysisResponse,
    EmbedRequest, EmbedResponse,
    SemanticSearchRequest,
    ExtractSkillsRequest, ExtractSkillsResponse,
    ExtractMotivationsRequest, ExtractMotivationsResponse
)
from engine import SemanticEngine
from database import get_db, WishSemantic, Base, engine as db_engine

# Setup Logging
logging.basicConfig(level=logging.INFO)

# Create tables if not exists
Base.metadata.create_all(bind=db_engine)

app = FastAPI(title="HGOS Semantic Engine", version="1.0.0")
engine = SemanticEngine()

@app.post("/analyzeWish", response_model=WishAnalysisResponse)
def analyze_wish(request: AnalyzeWishRequest, db: Session = Depends(get_db)):
    try:
        # Run deep semantic pipeline
        analysis_result = engine.analyze_wish(request.wish_text)
        
        # Save result to Database with vector embedding
        new_record = WishSemantic(
            wish_text=analysis_result.wish,
            embedding=analysis_result.embedding,
            analysis_json=analysis_result.model_dump()
        )
        db.add(new_record)
        db.commit()
        db.refresh(new_record)
        
        return analysis_result
    except Exception as e:
        logging.error(f"Error during analysis: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/embed", response_model=EmbedResponse)
def get_embedding(request: EmbedRequest):
    emb = engine.embed(request.text)
    return EmbedResponse(embedding=emb)

@app.post("/semanticSearch")
def semantic_search(request: SemanticSearchRequest, db: Session = Depends(get_db)):
    """Finds most similar wishes in the database using pgvector."""
    query_emb = engine.embed(request.query)
    
    # We use <=> for cosine distance in pgvector
    results = db.query(WishSemantic).order_by(
        WishSemantic.embedding.cosine_distance(query_emb)
    ).limit(request.top_k).all()
    
    return [
        {
            "id": str(r.id),
            "wish_text": r.wish_text,
            "analysis": r.analysis_json,
            "distance": float(r.embedding.cosine_distance(query_emb) if hasattr(r.embedding, 'cosine_distance') else 0.0) # ORM approximation
        } for r in results
    ]

@app.post("/extractSkills", response_model=ExtractSkillsResponse)
def extract_skills(request: ExtractSkillsRequest):
    # Specialized wrapper
    from extractors import extract_skills as extract_skills_func
    skills = extract_skills_func(request.goal, engine.embed)
    return ExtractSkillsResponse(skills=skills)

@app.post("/extractMotivations", response_model=ExtractMotivationsResponse)
def extract_motivations(request: ExtractMotivationsRequest):
    emb = engine.embed(request.wish_text)
    from models import Motivation
    extracted = engine.extractor.extract_all(request.wish_text, emb)
    motivations = [Motivation(**m) for m in extracted["motivations"]]
    return ExtractMotivationsResponse(motivations=motivations)
