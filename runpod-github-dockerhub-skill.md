# Skill: Conexión RunPod-GitHub-DockerHub con SSH Persistente

## Objetivo
Configurar un servidor RunPod para conectarse con GitHub usando SSH, ejecutar git operations y disparar GitHub Actions que construyen y publican imágenes Docker.

## Requisitos Previos
- Servidor RunPod con acceso SSH
- Credenciales SSH existentes (llave pública autorizada en GitHub)
- Cuenta DockerHub con token de acceso
- Repositorio GitHub existente

## Paso a Paso Completo

### 1. Configuración SSH en el Servidor

#### Crear directorio SSH
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
```

#### Configurar llave privada persistente
```bash
# Crear archivo de llave privada
nano ~/.ssh/id_ed25519
# Pegar la llave privada en formato OpenSSH completo:
# -----BEGIN OPENSSH PRIVATE KEY-----
# [contenido base64]
# -----END OPENSSH PRIVATE KEY-----

# Establecer permisos estrictos
chmod 600 ~/.ssh/id_ed25519
```

#### Configurar archivo SSH para GitHub
```bash
# Crear config file
cat > ~/.ssh/config << 'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
EOF
```

#### Agregar GitHub a known_hosts
```bash
ssh-keyscan github.com >> ~/.ssh/known_hosts
```

### 2. Verificación de Conexión SSH

#### Probar conexión con GitHub
```bash
ssh -T git@github.com
# Respuesta esperada: "Hi [username]! You've successfully authenticated"
```

### 3. Configuración del Proyecto

#### Crear directorio de trabajo
```bash
mkdir -p ~/poc-build && cd ~/poc-build
```

#### Inicializar repositorio Git
```bash
git init
git config user.email "tu-email@dominio.com"
git config user.name "Tu Nombre"
```

#### Configurar remote SSH
```bash
git remote add origin git@github.com:username/repo.git
```

### 4. Creación de Archivos del Proyecto

#### Dockerfile de prueba
```bash
cat > Dockerfile << 'EOF'
FROM alpine:latest
CMD ["echo", "¡Prueba de CI/CD exitosa!"]
EOF
```

#### GitHub Actions Workflow
```bash
mkdir -p .github/workflows
cat > .github/workflows/docker-publish.yml << 'EOF'
name: Docker Build and Push

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Log in to Docker Hub
      uses: docker/login-action@v3
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}

    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: tu-usuario/test-flow:latest
        platforms: linux/amd64,linux/arm64
EOF
```

### 5. Configuración de Secretos en GitHub

#### Secretos requeridos
- `DOCKER_USERNAME`: Tu usuario de DockerHub
- `DOCKER_PASSWORD`: Tu token de acceso de DockerHub

### 6. Git Operations

#### Primer commit y push
```bash
git add .
git commit -m "¡Prueba de CI/CD exitosa!"
git branch -m main
git push -u origin main
```

#### Disparar build con commit vacío
```bash
git commit --allow-empty -m "¡Prueba de CI/CD exitosa!"
git push
```

## Comandos Clave que Funcionaron

### SSH Setup
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
ssh-keyscan github.com >> ~/.ssh/known_hosts
ssh -T git@github.com
```

### Git Operations
```bash
git init
git config user.email "email@dominio.com"
git config user.name "Nombre Usuario"
git remote add origin git@github.com:username/repo.git
git add .
git commit -m "mensaje"
git push -u origin main
```

### CI/CD Trigger
```bash
git commit --allow-empty -m "trigger build"
git push
```

## Verificación

### Monitoreo
- GitHub Actions: `github.com/username/repo/actions`
- DockerHub: Verificar imagen `username/test-flow:latest`

### Troubleshooting
- Si SSH falla: verificar permisos (`chmod 600 ~/.ssh/id_ed25519`)
- Si git push falla: verificar configuración SSH en `~/.ssh/config`
- Si build falla: verificar secretos en GitHub Settings

## Notas Importantes
- La llave SSH debe estar en formato OpenSSH completo
- Los permisos SSH deben ser 700 para directorio, 600 para archivo
- El workflow usa multi-platform build (amd64, arm64)
- Los secretos de DockerHub deben configurarse en GitHub

## Próximos Pasos
1. Monitorear ejecución del workflow
2. Verificar imagen en DockerHub
3. Probar imagen localmente: `docker run tu-usuario/test-flow:latest`
