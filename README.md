# Runpod_Comfy_Ultime (CUDA 12.8)

ComfyUI + ComfyUI-Manager, Jupyter optionnel, **installation runtime** (Torch/HF), et **manifests externes** pour nodes / modèles / workflows.
Compatible RunPod (amd64).

## Points clés
- Image base: `nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04`
- Jupyter activable via `ENABLE_JUPYTER`
- ComfyUI-Manager préinstallé
- Torch + stack HF installées **au démarrage** (pas pendant la build)
- `extra_model_paths.yaml` robuste (mapping par familles)
- Manifests `manifests/*.txt` pour nodes / modèles / workflows
- `NODES_INSTALL_MODE=sync|async` (sync = évite les noeuds rouges)

## ENV recommandées (RunPod)
```
ENABLE_JUPYTER=true
JUPYTER_PORT=8888
COMFY_AUTOSTART=true
COMFY_ARGS=--listen 0.0.0.0 --port 8188 --use-sage-attention

DATA_DIR=/workspace
COMFY_DIR=/opt/ComfyUI
MODELS_DIR=/workspace/models
COMFY_WORKFLOWS_SRC=/workspace/workflows
COMFY_WORKFLOWS_MODE=symlink

CUSTOM_NODES_MANIFEST=/manifests/nodes_manifest.txt
MODELS_MANIFEST=/manifests/models_manifest.txt
WORKFLOWS_MANIFEST=/manifests/workflows_manifest.txt
NODES_INSTALL_MODE=sync

COMFY_UPDATE_AT_START=false
COMFY_REF_RUNTIME=

TORCH_INDEX_URL=https://download.pytorch.org/whl/cu128
# Optionnel:
# TORCH_SPEC_TORCH=torch==2.7.0
# TORCH_SPEC_VISION=torchvision==0.22.0
# TORCH_SPEC_AUDIO=torchaudio==2.7.0

# Secrets (mieux via *_FILE)
# JUPYTER_TOKEN_FILE=/run/secrets/jupyter_token
# HF_TOKEN_FILE=/run/secrets/hf_token
```

## Build & Push (local)
```
docker buildx build --platform linux/amd64   -t docker.io/mauricebourdondock/runpod-comfy-ultime-cu128:runpod-amd64   -t docker.io/mauricebourdondock/runpod-comfy-ultime-cu128:latest   --push .
```

## Run local
```
docker run --rm -it --gpus all -p 8188:8188 -p 8888:8888   -e ENABLE_JUPYTER=true   -e COMFY_AUTOSTART=true   -e COMFY_ARGS="--listen 0.0.0.0 --port 8188 --use-sage-attention"   -e NODES_INSTALL_MODE=sync   -v $PWD/workspace:/workspace   -v $PWD/persist_models:/workspace/models   docker.io/mauricebourdondock/runpod-comfy-ultime-cu128:latest
```

## RunPod
- Image: `docker.io/mauricebourdondock/runpod-comfy-ultime-cu128:runpod-amd64` (ou `:latest`)
- Ports: 8188 (ComfyUI), 8888 (Jupyter)
- Volume: `/workspace`
