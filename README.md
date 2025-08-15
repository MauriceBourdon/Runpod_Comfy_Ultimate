# Runpod Comfy Ultime — CUDA 12.8, symlinks & manifest modèles (SageAttention inclus)

- CUDA **12.8** + **torch cu128** préinstallé
- ComfyUI + **ComfyUI-Manager**
- **SageAttention & Triton pré-installés**, et ComfyUI démarre avec `--use-sage-attention` par défaut
- JupyterLab (port 8888) optionnel
- **Symlinks** propres vers `/workspace/{ComfyUI,workflows,input,output}`
- **Manifest modèles** éditable à chaud (`/workspace/models_manifest.txt`)
- Commandes: `pull-models`

## Variables d'environnement (RunPod)
```
ENABLE_JUPYTER=true
JUPYTER_PORT=8888
COMFY_AUTOSTART=true
COMFY_PORT=8188
COMFY_ARGS=--listen 0.0.0.0 --port 8188 --use-sage-attention

DATA_DIR=/workspace
COMFY_DIR=/opt/ComfyUI
MODELS_DIR=/workspace/models
MODELS_MANIFEST=/workspace/models_manifest.txt

PIP_CACHE_DIR=/workspace/.pip-cache
PIP_NO_CACHE_DIR=0
# HF_TOKEN=... (si besoin d'accès privé)
```

## Quick start
1. Lance le pod, Jupyter & ComfyUI montent (SageAttention actif par défaut).
2. Édite `/workspace/models_manifest.txt` (ou copie depuis `/manifests`).
3. `pull-models --sync` puis rafraîchis l'UI ComfyUI.

Plus de détails dans **docs/MODELS.md** et **docs/SAGE.md**.
