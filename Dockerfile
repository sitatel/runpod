FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

# Establecer directorio de trabajo
WORKDIR /app

# Instalar dependencias básicas
RUN apt-get update && apt-get install -y \
    wget \
    git \
    python3 \
    python3-pip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copiar todos los archivos del proyecto al contenedor
COPY . /app/

# Dar permisos de ejecución al script
RUN chmod +x /app/start_services.sh

# Crear enlace simbólico para mantener compatibilidad con /workspace
RUN ln -sf /app /workspace

# Exponer puertos
EXPOSE 7860 8001

# Comando de inicio
CMD ["/app/start_services.sh"]
