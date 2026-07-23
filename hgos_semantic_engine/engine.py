import torch
import logging
from sentence_transformers import SentenceTransformer
from typing import List

from models import WishAnalysisResponse, Motivation, Personality
from extractors import ZeroShotExtractor, extract_primary_goal, extract_keywords_entities, extract_skills

logger = logging.getLogger(__name__)

class SemanticEngine:
    def __init__(self, model_name: str = "distilbert-base-uncased"):
        """
        Initializes the Semantic Engine using a DistilBERT-based model.
        """
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info(f"Loading {model_name} on {self.device}...")
        
        # SentenceTransformers wraps raw transformer models and adds mean pooling
        self.model = SentenceTransformer(model_name, device=self.device)
        
        # Initialize zero-shot extractor with the model's embed function
        self.extractor = ZeroShotExtractor(self.embed)
        logger.info("Semantic Engine initialized successfully.")

    def embed(self, text: str) -> List[float]:
        """Generates a dense vector representation for the given text."""
        # Convert to numpy and then to standard python list for JSON serialization
        return self.model.encode(text, convert_to_numpy=True).tolist()

    def analyze_wish(self, wish_text: str) -> WishAnalysisResponse:
        """
        Runs the full semantic pipeline to extract goals, motivations,
        emotions, skills, and more from a raw wish text.
        """
        # 1. Generate semantic embedding
        emb = self.embed(wish_text)
        
        # 2. Extract Goal, Keywords, Entities
        goal = extract_primary_goal(wish_text)
        keywords, entities = extract_keywords_entities(wish_text)
        
        # 3. Predict Required Skills based on Goal
        skills = extract_skills(goal, self.embed)
        
        # 4. Zero-shot classifications
        extracted = self.extractor.extract_all(wish_text, emb)
        
        # 5. Assemble and validate payload
        motivations = [Motivation(**m) for m in extracted["motivations"]]
        personality = Personality(**extracted["personality"])
        
        return WishAnalysisResponse(
            wish=wish_text,
            embedding=emb,
            primary_goal=goal,
            life_domains=extracted["life_domains"],
            motivations=motivations,
            emotions=extracted["emotions"],
            constraints=extracted["constraints"],
            required_skills=skills,
            values=extracted["values"],
            personality=personality,
            growth_stage=extracted["growth_stage"],
            keywords=keywords,
            entities=entities
        )
