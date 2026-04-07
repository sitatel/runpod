# Parche para inyectar OpenAIInferenceModel en inference.py
# Este parche es crítico para que la inferencia funcione

import requests
import json
from typing import List, Dict, Any

class OpenAIInferenceModel:
    """Clase para conectar con el servidor vLLM via API OpenAI"""
    
    def __init__(self, base_url: str = "http://localhost:8001/v1"):
        self.base_url = base_url
        self.model_name = "llama-3-8b-instruct-awq"
    
    def generate(self, prompt: str, **kwargs) -> str:
        """Genera texto usando el servidor vLLM"""
        try:
            response = requests.post(
                f"{self.base_url}/completions",
                json={
                    "model": self.model_name,
                    "prompt": prompt,
                    "max_tokens": kwargs.get("max_tokens", 512),
                    "temperature": kwargs.get("temperature", 0.7),
                }
            )
            response.raise_for_status()
            return response.json()["choices"][0]["text"]
        except Exception as e:
            print(f"Error en OpenAIInferenceModel: {e}")
            return ""

# Inyectar la clase en el módulo actual
import sys
sys.modules[__name__].OpenAIInferenceModel = OpenAIInferenceModel
