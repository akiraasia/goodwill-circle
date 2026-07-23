from pydantic import BaseModel, Field
from typing import List, Dict, Optional

class Motivation(BaseModel):
    label: str
    confidence: float

class Personality(BaseModel):
    openness: float = Field(..., ge=0.0, le=1.0)
    conscientiousness: float = Field(..., ge=0.0, le=1.0)
    extraversion: float = Field(..., ge=0.0, le=1.0)
    agreeableness: float = Field(..., ge=0.0, le=1.0)
    neuroticism: float = Field(..., ge=0.0, le=1.0)

class WishAnalysisResponse(BaseModel):
    wish: str
    embedding: List[float] = Field(description="768-dimensional dense vector")
    primary_goal: str
    life_domains: List[str]
    motivations: List[Motivation]
    emotions: Dict[str, float] = Field(description="Emotion labels and their probabilities")
    constraints: List[str]
    required_skills: List[str]
    values: List[str]
    personality: Personality
    growth_stage: str
    keywords: List[str]
    entities: List[str]

class AnalyzeWishRequest(BaseModel):
    wish_text: str = Field(..., min_length=2, max_length=2000)

class SemanticSearchRequest(BaseModel):
    query: str
    top_k: int = Field(default=5, ge=1, le=50)

class EmbedRequest(BaseModel):
    text: str
    
class EmbedResponse(BaseModel):
    embedding: List[float]

class ExtractSkillsRequest(BaseModel):
    goal: str

class ExtractSkillsResponse(BaseModel):
    skills: List[str]

class ExtractMotivationsRequest(BaseModel):
    wish_text: str

class ExtractMotivationsResponse(BaseModel):
    motivations: List[Motivation]
