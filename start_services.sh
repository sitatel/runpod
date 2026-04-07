#!/bin/bash

echo "=== Iniciando servicios FishSpeech ==="

# 1. Verificar e instalar Miniconda si no existe
if [ ! -d "/workspace/miniconda3" ]; then
    echo "Instalando Miniconda en /workspace/miniconda3..."
    mkdir -p /workspace/miniconda3
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /workspace/miniconda.sh
    bash /workspace/miniconda.sh -b -u -p /workspace/miniconda3
    rm /workspace/miniconda.sh
fi

# 2. Inicializar conda
source /workspace/miniconda3/bin/activate
conda init bash
source ~/.bashrc

# 3. Crear entorno si no existe
if ! conda env list | grep -q "fish-speech"; then
    echo "Creando entorno fish-speech..."
    conda create -n fish-speech python=3.10 -y
fi

# 4. Activar entorno
conda activate fish-speech

# 5. Instalar FishSpeech si no existe
if [ ! -d "/workspace/fish-speech" ]; then
    echo "Clonando FishSpeech..."
    cd /workspace
    git clone https://github.com/fishaudio/fish-speech.git
fi

cd /workspace/fish-speech

# 6. Instalar dependencias
echo "Instalando dependencias..."
conda install -c conda-forge portaudio -y
pip install -e .

# 7. Descargar modelo si no existe
if [ ! -d "/workspace/checkpoints/s2-pro" ]; then
    echo "Descargando modelo s2-pro..."
    mkdir -p /workspace/checkpoints
    hf download fishaudio/s2-pro --local-dir checkpoints/s2-pro
fi

# 8. Instalar herramientas adicionales
pip install huggingface_hub vllm bitsandbytes accelerate

# 9. Descargar modelo Llama si no existe
if [ ! -d "/workspace/checkpoints/llama-3-awq" ]; then
    echo "Descargando modelo Llama-3-AWQ..."
    python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='casperhansen/llama-3-8b-instruct-awq', local_dir='/workspace/checkpoints/llama-3-awq')"
fi

# 10. Iniciar vLLM en segundo plano
echo "Iniciando servidor vLLM en puerto 8001..."
python -m vllm.entrypoints.openai.api_server \
    --model /workspace/checkpoints/llama-3-awq \
    --quantization awq \
    --dtype half \
    --gpu-memory-utilization 0.4 \
    --max-model-len 4096 \
    --port 8001 &

# Esperar a que vLLM esté listo
sleep 10

# 11. Iniciar servidor de inferencia FishSpeech
echo "Iniciando servidor de inferencia FishSpeech en puerto 7860..."
source /workspace/miniconda3/etc/profile.d/conda.sh && \
conda activate fish-speech && \
python tools/api_server.py \
    --llama-checkpoint-path http://localhost:8001/v1 \
    --decoder-checkpoint-path /workspace/checkpoints/s2-pro/checkpoints/s2-pro/codec.pth \
    --decoder-config-name modded_dac_vq \
    --device cuda \
    --listen 0.0.0.0:7860
