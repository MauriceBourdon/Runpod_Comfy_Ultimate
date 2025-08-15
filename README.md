# ComfyUI cu12.8 — Symlink + External Model Manifest

- CUDA 12.8 + **torch cu128** préinstallé
- ComfyUI + ComfyUI-Manager
- JupyterLab (8888) optionnel
- **Symlinks** pratiques dans `/workspace`: `ComfyUI`, `workflows`, `input`, `output`
- **Manifest modèles éditable** dans `/workspace/models_manifest.txt` + commande `pull-models`

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

## Éditer la liste de modèles
- Ouvre `/workspace/models_manifest.txt` dans JupyterLab, modifie, puis:
  - `pull-models` (async) ou `pull-models --sync` (bloquant)
  - Log: `/workspace/models_download.log`

Format d'une ligne du manifest: `repo|fichier|sous_dossier`
```
Kijai/WanVideo_comfy|Wan2_2_VAE_bf16.safetensors|vae
```

Bonne session !
