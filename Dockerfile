# Dockerfile Ultra-Slim para FishSpeech
FROM python:3.10-slim

# Establecer variables de entorno
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Instalar dependencias básicas del sistema
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Crear directorios de trabajo
RUN mkdir -p /workspace/checkpoints/s2-pro
RUN mkdir -p /workspace/checkpoints/llama-3-awq

# Copiar scripts y parches
COPY patches/inference.py /tmp/inference.py
COPY start_services.sh /workspace/start_services.sh
RUN chmod +x /workspace/start_services.sh

# Exponer puertos
EXPOSE 7860 8001

# Comando de inicio por defecto
CMD ["/workspace/start_services.sh"]

# Directorio de trabajo
WORKDIR /workspace
