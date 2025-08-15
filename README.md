# Runpod ComfyUI v4.1.3 — models-only

- CUDA 12.8 + PyTorch cu128 **préinstallé** (build)
- ComfyUI + ComfyUI-Manager installés
- Jupyter Lab optionnel (8888)
- **Pas d'installation de nœuds** au démarrage
- Téléchargement **asynchrone** des modèles depuis `manifests/models_manifest.txt`

## Variables RunPod
```
ENABLE_JUPYTER=true
JUPYTER_PORT=8888
# JUPYTER_TOKEN=... (optionnel)

COMFY_AUTOSTART=true
COMFY_PORT=8188
COMFY_ARGS=--listen 0.0.0.0 --port 8188 --use-sage-attention

DATA_DIR=/workspace
COMFY_DIR=/opt/ComfyUI
MODELS_DIR=/workspace/models
MODELS_MANIFEST=/manifests/models_manifest.txt

PIP_CACHE_DIR=/workspace/.pip-cache
PIP_NO_CACHE_DIR=0
# HF_TOKEN=<si private repos HF>
```
