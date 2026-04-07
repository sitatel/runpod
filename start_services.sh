#!/bin/bash
set -e
echo "=== 🚀 INICIANDO AUTOMATIZACIÓN TOTAL SAE VOICE ENGINE ==="

# 1. CREACIÓN AUTOMÁTICA DE LA ESTRUCTURA (Para que tú no hagas nada)
echo "Configurando esqueleto de directorios..."
mkdir -p /workspace/miniconda3
mkdir -p /workspace/checkpoints/s2-pro
mkdir -p /workspace/checkpoints/llama-3-awq
mkdir -p /workspace/fish-speech

# 2. INSTALACIÓN DE CONDA (Solo si no está)
if [ ! -f "/workspace/miniconda3/bin/conda" ]; then
    echo "Instalando Miniconda en volumen persistente..."
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -u -p /workspace/miniconda3
    rm /tmp/miniconda.sh
fi
source /workspace/miniconda3/bin/activate

# 3. ENTORNO Y DEPENDENCIAS
if ! conda env list | grep -q "fish-speech"; then
    echo "Creando entorno Python 3.10..."
    conda create -n fish-speech python=3.10 -y
fi
conda activate fish-speech

# 4. CÓDIGO FUENTE
if [ ! -d "/workspace/fish-speech/.git" ]; then
    echo "Clonando motor FishSpeech..."
    cd /workspace
    git clone https://github.com/fishaudio/fish-speech.git
fi
cd /workspace/fish-speech
pip install -e .
pip install vllm bitsandbytes accelerate huggingface_hub openai

# 5. DESCARGA AUTOMÁTICA DE MODELOS (Si no están listos)
echo "Verificando pesos del modelo..."
python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='fishaudio/s2-pro', local_dir='/workspace/checkpoints/s2-pro')"
python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='casperhansen/llama-3-8b-instruct-awq', local_dir='/workspace/checkpoints/llama-3-awq')"

# 6. ARRANQUE DE SERVICIOS
echo "Levantando vLLM en puerto 8001..."
python -m vllm.entrypoints.openai.api_server --model /workspace/checkpoints/llama-3-awq --quantization awq --dtype half --gpu-memory-utilization 0.4 --port 8001 --host 0.0.0.0 &
VLLM_PID=$!

sleep 15 # Espera mínima inicial

echo "Levantando API FishSpeech en puerto 7860..."
python tools/api_server.py --llama-checkpoint-path http://localhost:8001/v1 --decoder-checkpoint-path /workspace/checkpoints/s2-pro/checkpoints/s2-pro/codec.pth --decoder-config-name modded_dac_vq --device cuda --listen 0.0.0.0:7860

kill $VLLM_PID
