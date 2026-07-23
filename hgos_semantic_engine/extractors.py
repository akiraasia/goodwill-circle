import numpy as np
import re
from typing import List, Dict

DOMAINS = ["Career", "Education", "Relationships", "Health", "Finance", "Family", "Spirituality", "Community", "Creativity", "Personal Growth"]
MOTIVATIONS = ["Freedom", "Security", "Family", "Recognition", "Purpose", "Helping Others", "Confidence", "Adventure", "Creativity", "Self-expression"]
EMOTIONS = ["Hope", "Fear", "Anxiety", "Excitement", "Regret", "Loneliness", "Joy", "Curiosity", "Burnout", "Frustration"]
VALUES = ["Helping Others", "Achievement", "Freedom", "Stability", "Learning", "Family", "Adventure", "Justice", "Creativity", "Community"]
GROWTH_STAGES = ["Exploring", "Planning", "Beginning", "Building", "Struggling", "Recovering", "Mastering", "Teaching"]
CONSTRAINTS = ["Money", "Time", "Confidence", "Location", "Family Pressure", "Health", "Knowledge", "Resources"]

def cosine_similarity(vec1, vec2):
    vec1 = np.array(vec1)
    vec2 = np.array(vec2)
    norm = np.linalg.norm(vec1) * np.linalg.norm(vec2)
    if norm == 0:
        return 0.0
    return np.dot(vec1, vec2) / norm

class ZeroShotExtractor:
    def __init__(self, embed_func):
        self.embed_func = embed_func
        
        # Precompute embeddings for all taxonomies to make inference fast
        self.domain_embeddings = {k: self.embed_func(k) for k in DOMAINS}
        self.motivation_embeddings = {k: self.embed_func(k) for k in MOTIVATIONS}
        self.emotion_embeddings = {k: self.embed_func(k) for k in EMOTIONS}
        self.value_embeddings = {k: self.embed_func(k) for k in VALUES}
        self.stage_embeddings = {k: self.embed_func(k) for k in GROWTH_STAGES}
        self.constraint_embeddings = {k: self.embed_func(k) for k in CONSTRAINTS}

        # Personality trait anchors (Big Five)
        self.personality_anchors = {
            "openness": (self.embed_func("creative open minded curious exploring imagination"), 
                         self.embed_func("routine traditional closed conventional strict")),
            "conscientiousness": (self.embed_func("organized disciplined hard working planning goal-oriented"), 
                                  self.embed_func("messy lazy impulsive unorganized chaotic")),
            "extraversion": (self.embed_func("outgoing social talkative energetic people"), 
                             self.embed_func("quiet reserved solitary introverted alone")),
            "agreeableness": (self.embed_func("friendly compassionate cooperative kind helpful"), 
                              self.embed_func("critical harsh argumentative selfish cold")),
            "neuroticism": (self.embed_func("anxious nervous stressed worrying unstable"), 
                            self.embed_func("calm stable relaxed confident resilient"))
        }

    def _rank(self, text_emb, embeddings_dict, threshold=0.0):
        results = []
        for label, emb in embeddings_dict.items():
            sim = cosine_similarity(text_emb, emb)
            if sim > threshold:
                confidence = float(max(0, sim))
                results.append((label, confidence))
        return sorted(results, key=lambda x: x[1], reverse=True)

    def extract_all(self, text: str, text_emb: list) -> Dict:
        """Runs all semantic zero-shot extractions on the given embedding."""
        
        # 1. Life Domains
        domains = [r[0] for r in self._rank(text_emb, self.domain_embeddings, threshold=0.25)[:3]]
        
        # 2. Motivations
        m_ranked = self._rank(text_emb, self.motivation_embeddings)
        motivations = [{"label": r[0], "confidence": r[1]} for r in m_ranked[:4]]
        
        # 3. Emotions (return all with positive similarity > 0.1)
        e_ranked = self._rank(text_emb, self.emotion_embeddings)
        emotions = {r[0]: r[1] for r in e_ranked if r[1] > 0.15}
        
        # 4. Values
        values = [r[0] for r in self._rank(text_emb, self.value_embeddings, threshold=0.25)[:3]]
        
        # 5. Constraints
        constraints = [r[0] for r in self._rank(text_emb, self.constraint_embeddings, threshold=0.2)[:3]]
        
        # 6. Growth Stage
        best_stage = self._rank(text_emb, self.stage_embeddings)[0][0]
        
        # 7. Personality Traits
        personality = {}
        for trait, (high_emb, low_emb) in self.personality_anchors.items():
            sim_high = max(0.01, cosine_similarity(text_emb, high_emb))
            sim_low = max(0.01, cosine_similarity(text_emb, low_emb))
            total = sim_high + sim_low
            score = sim_high / total
            personality[trait] = float(score)
            
        return {
            "life_domains": domains,
            "motivations": motivations,
            "emotions": emotions,
            "values": values,
            "constraints": constraints,
            "growth_stage": best_stage,
            "personality": personality
        }

def extract_primary_goal(text: str) -> str:
    cleaned = re.sub(r'^(i want to|i wish to|i would like to|my goal is to|i need to)\s+', '', text, flags=re.IGNORECASE)
    return cleaned.strip().capitalize()

def extract_keywords_entities(text: str) -> tuple:
    words = re.findall(r'\b\w+\b', text)
    keywords = list(set([w.lower() for w in words if len(w) > 4]))
    entities = list(set([w for w in words if w[0].isupper() and len(w) > 2 and w.lower() not in ["the", "this", "that"]]))
    return keywords, entities

def extract_skills(goal: str, embed_func) -> List[str]:
    SKILL_BANK = [
        "Biology", "Discipline", "Communication", "Study Habit", "Resilience", 
        "Time Management", "Programming", "Leadership", "Finance", "Writing", 
        "Public Speaking", "Networking", "Design", "Problem Solving", "Empathy"
    ]
    goal_emb = embed_func(goal)
    results = []
    for s in SKILL_BANK:
        sim = cosine_similarity(goal_emb, embed_func(s))
        results.append((s, sim))
    results.sort(key=lambda x: x[1], reverse=True)
    return [r[0] for r in results[:5]]
