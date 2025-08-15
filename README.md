# ComfyUI cu12.8 — Symlink + External Model Manifest (v3)

- CUDA 12.8 + **torch cu128** préinstallé
- ComfyUI + ComfyUI-Manager
- JupyterLab (8888) optionnel
- Symlinks robustes (`safe_link`) vers `/workspace/{ComfyUI,workflows,input,output}`
- Manifest modèles éditable dans `/workspace/models_manifest.txt`
- Commande `pull-models` (async/sync/status/watch)

## Variables RunPod
```
ENABLE_JUPYTER=true
JUPYTER_PORT=8888
# JUPYTER_TOKEN=...

COMFY_AUTOSTART=true
COMFY_PORT=8188
COMFY_ARGS=--listen 0.0.0.0 --port 8188

DATA_DIR=/workspace
COMFY_DIR=/opt/ComfyUI
MODELS_DIR=/workspace/models
MODELS_MANIFEST=/workspace/models_manifest.txt

PIP_CACHE_DIR=/workspace/.pip-cache
PIP_NO_CACHE_DIR=0
# HF_TOKEN=... (si besoin)
```

## Utilisation
- Édite `/workspace/models_manifest.txt` puis:
  - `pull-models` (async) ou `pull-models --sync`
  - `pull-models --status` pour voir le log

Log: `/workspace/models_download.log`
