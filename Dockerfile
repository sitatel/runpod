# Dockerfile Natural para SAE Voice Engine
FROM python:3.10-slim

# Entorno
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Dependencias
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# CREACIÓN DE DIRECTORIOS (El esqueleto que mencionas)
RUN mkdir -p /workspace/checkpoints/s2-pro
RUN mkdir -p /workspace/checkpoints/llama-3-awq

# Copiar el script de inicio (SIN PARCHES)
COPY start_services.sh /workspace/start_services.sh
RUN chmod +x /workspace/start_services.sh

# Configuración final
EXPOSE 7860 8001
WORKDIR /workspace
CMD ["/workspace/start_services.sh"]
