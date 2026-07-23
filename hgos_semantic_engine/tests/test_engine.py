import pytest
import sys
import os

# Add parent directory to path to import local modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from engine import SemanticEngine
from models import WishAnalysisResponse

@pytest.fixture(scope="module")
def semantic_engine():
    # Use distilbert for lightweight testing
    return SemanticEngine(model_name="distilbert-base-uncased")

def test_embed(semantic_engine):
    text = "Testing the embedding function."
    emb = semantic_engine.embed(text)
    
    assert isinstance(emb, list)
    assert len(emb) == 768
    assert isinstance(emb[0], float)

def test_analyze_wish(semantic_engine):
    text = "I want to become a doctor so I can help my community and family."
    response = semantic_engine.analyze_wish(text)
    
    assert isinstance(response, WishAnalysisResponse)
    assert response.wish == text
    
    # Check primary goal extraction
    assert response.primary_goal.lower().startswith("become a doctor")
    
    # Check that some zero-shot classifications were made
    assert len(response.life_domains) > 0
    assert len(response.motivations) > 0
    assert len(response.emotions) > 0
    assert len(response.required_skills) > 0
    assert len(response.values) > 0
    assert len(response.constraints) > 0
    assert isinstance(response.growth_stage, str)
    
    # Personality boundaries
    assert 0.0 <= response.personality.openness <= 1.0
    assert 0.0 <= response.personality.conscientiousness <= 1.0
    assert 0.0 <= response.personality.extraversion <= 1.0
    assert 0.0 <= response.personality.agreeableness <= 1.0
    assert 0.0 <= response.personality.neuroticism <= 1.0
