#!/bin/bash

# Script de inicio para FishSpeech - Instalación completa en runtime
set -e

echo "=== Iniciando configuración de FishSpeech ==="

# Instalar Miniconda si no existe
if [ ! -d "/workspace/miniconda3" ]; then
    echo "Instalando Miniconda..."
    mkdir -p /workspace/miniconda3
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /workspace/miniconda.sh
    bash /workspace/miniconda.sh -b -u -p /workspace/miniconda3
    rm /workspace/miniconda.sh
    /workspace/miniconda3/bin/conda init bash
fi

# Activar entorno conda
source /workspace/miniconda3/bin/activate

# Crear entorno fish-speech si no existe
if ! conda env list | grep -q "fish-speech"; then
    echo "Creando entorno fish-speech..."
    conda create -n fish-speech python=3.10 -y
fi

# Activar entorno fish-speech
conda activate fish-speech

# Clonar FishSpeech si no existe
if [ ! -d "/workspace/fish-speech" ]; then
    echo "Clonando FishSpeech..."
    cd /workspace
    git clone https://github.com/fishaudio/fish-speech.git
fi

# Instalar dependencias si no están instaladas
cd /workspace/fish-speech

# Verificar si FishSpeech está instalado
if ! python -c "import fish_speech" 2>/dev/null; then
    echo "Instalando FishSpeech y dependencias..."
    # Instalar dependencias de audio
    apt-get update && apt-get install -y portaudio19-dev && rm -rf /var/lib/apt/lists/*
    
    # Instalar FishSpeech en modo editable
    pip install -e .
    
    # Instalar herramientas de cuantización
    pip install vllm bitsandbytes accelerate huggingface_hub openai
    
    # Verificar instalación
    python -c "import vllm; print(f'vLLM version: {vllm.__version__}')"
fi

# Aplicar parche si no está aplicado
if [ ! -f "/workspace/fish-speech/fish_speech/models/text2semantic/inference.py.bak" ]; then
    echo "Aplicando parche de inference.py..."
    cp /workspace/fish-speech/fish_speech/models/text2semantic/inference.py /workspace/fish-speech/fish_speech/models/text2semantic/inference.py.bak
    cp /tmp/inference.py /workspace/fish-speech/fish_speech/models/text2semantic/inference.py
fi

echo "=== Descargando modelos requeridos ==="

# Descargar s2-pro si no existe
if [ ! -d "/workspace/checkpoints/s2-pro/checkpoints" ]; then
    echo "Descargando s2-pro..."
    python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='fishaudio/s2-pro', local_dir='/workspace/checkpoints/s2-pro')"
fi

# Descargar llama-3-8b-instruct-awq si no existe
if [ ! -d "/workspace/checkpoints/llama-3-awq" ] || [ ! -f "/workspace/checkpoints/llama-3-awq/config.json" ]; then
    echo "Descargando Llama-3 AWQ..."
    python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='casperhansen/llama-3-8b-instruct-awq', local_dir='/workspace/checkpoints/llama-3-awq')"
fi

echo "=== Modelos descargados. Iniciando servidor vLLM ==="

# Iniciar servidor vLLM en background
python -m vllm.entrypoints.openai.api_server \
    --model /workspace/checkpoints/llama-3-awq \
    --quantization awq \
    --dtype half \
    --gpu-memory-utilization 0.4 \
    --max-model-len 4096 \
    --port 8001 \
    --host 0.0.0.0 &

VLLM_PID=$!

# Esperar a que vLLM esté listo
echo "Esperando a que vLLM esté listo..."
while ! curl -s http://localhost:8001/v1/models > /dev/null 2>&1; do
    echo "vLLM no está listo aún, esperando 10 segundos..."
    sleep 10
done

echo "=== vLLM listo! Iniciando API de FishSpeech ==="

# Iniciar API de FishSpeech
python tools/api_server.py \
    --llama-checkpoint-path http://localhost:8001/v1 \
    --decoder-checkpoint-path /workspace/checkpoints/s2-pro/checkpoints/s2-pro/codec.pth \
    --decoder-config-name modded_dac_vq \
    --device cuda \
    --listen 0.0.0.0:7860

# Si FishSpeech termina, también terminar vLLM
kill $VLLM_PID
