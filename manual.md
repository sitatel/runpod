# Despliegue FishSpeech

## 1. Preparación del Entorno (Conda en /workspace)

Instalamos Miniconda directamente en el volumen de red para que no se borre nunca.

Bash

`# Crear directorio en el volumen montado
mkdir -p /workspace/miniconda3

# Descargar e instalar directamente en la ruta persistente
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /workspace/miniconda.sh
bash /workspace/miniconda.sh -b -u -p /workspace/miniconda3
rm /workspace/miniconda.sh

# Inicializar para el shell actual
source /workspace/miniconda3/bin/activate
conda init bash
source ~/.bashrc`

## 2. Creación del Entorno Aislado

Configuramos el aislamiento para el proyecto de voz.

Bash

`# Crear y activar entorno con Python 3.10
conda create -n fish-speech python=3.10 -y
conda activate fish-speech`

## 3. Instalación de Dependencias y Código

⚠️ NOTA CRÍTICA DE CÓDIGO: > Antes de ejecutar el comando final de Inferencia, es obligatorio haber aplicado el parche manual en /workspace/fish-speech/fish_speech/models/text2semantic/inference.py.
Sin la clase OpenAIInferenceModel inyectada en ese archivo, el comando de inferencia fallará al intentar conectar con el puerto 800

`# Entrar al volumen persistente
cd /workspace

# Clonar si no existe
git clone https://github.com/fishaudio/fish-speech.git
cd fish-speech

# Dependencia de audio y modo editable
conda install -c conda-forge portaudio -y
pip install -e .`

`# Descargamos los pesos a la ruta persistente
hf download fishaudio/s2-pro --local-dir checkpoints/s2-pro`

`# Instalamos la herramienta de Hugging Face si no está
pip install huggingface_hub`

`cd /workspace/fish-speech`

####################################################################

**RUTA CUANTIZADA: INSTALAR HERRAMIENTAS DE CUANTIZACION**

###################################################################

INSTALAR VLLM

pip install vllm

python -c "import vllm; print(vllm.**version**)"

pip install bitsandbytes accelerate

huggingface-cli login

DESCARGAR MODELO INT4

python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='casperhansen/llama-3-8b-instruct-awq', local_dir='/workspace/checkpoints/llama-3-awq')”

ARRANCAR SERVICIOS vLLM

python -m vllm.entrypoints.openai.api_server \
--model /workspace/checkpoints/llama-3-awq \
--quantization awq \
--dtype half \
--gpu-memory-utilization 0.4 \
--max-model-len 4096 \
--port 8001

INFERENCIA CUANTIZADA INT4

source /workspace/miniconda3/etc/profile.d/conda.sh && \
conda activate fish-speech && \
python tools/api_server.py \
--llama-checkpoint-path http://localhost:8001/v1 \
--decoder-checkpoint-path /workspace/checkpoints/s2-pro/checkpoints/s2-pro/codec.pth \
--decoder-config-name modded_dac_vq \
--device cuda \
--listen 0.0.0.0:7860