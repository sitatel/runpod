# FishSpeech - Modelo de Voz Cuantizado

## Descripción
Contenedor Docker con FishSpeech y vLLM para generación de voz cuantizada.

## Arquitectura
- **FishSpeech**: Servidor de inferencia de voz en puerto 7860
- **vLLM**: Servidor LLM cuantizado en puerto 8001
- **Modelos**: Llama-3-8B-AWQ (INT4) + FishSpeech S2-Pro

## Uso
```bash
docker run -d \
  --name fishspeech \
  --gpus all \
  -v /workspace:/workspace \
  -p 7860:7860 \
  -p 8001:8001 \
  fishspeech:latest
```

## Características
- Instalación automática en primer arranque
- Datos persistentes en /workspace
- Modelos pre-descargados
- Optimizado para GPU

## Build
```bash
docker build -t fishspeech:latest .
```

## Créditos
- [FishAudio](https://github.com/fishaudio/fish-speech)
- [vLLM](https://github.com/vllm-project/vllm)
