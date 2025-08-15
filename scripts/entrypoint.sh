#!/usr/bin/env bash
set -euo pipefail

export PATH="/venv/bin:$PATH"
mkdir -p "${DATA_DIR:-/workspace}" "${MODELS_DIR:-/workspace/models}" "${PIP_CACHE_DIR:-/workspace/.pip-cache}"

if ! python -c "import torch" >/dev/null 2>&1; then
  if ! pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cu128 torch torchvision torchaudio; then
    pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu torch torchvision torchaudio
  fi
fi

python - <<'PY' || pip install --no-cache-dir huggingface-hub==0.24.6 safetensors==0.4.5
import importlib; importlib.import_module("huggingface_hub"); importlib.import_module("safetensors")
PY

cat >"${COMFY_DIR:-/opt/ComfyUI}/extra_model_paths.yaml" <<'YAML'
models_dir: |
  /workspace/models
  /opt/ComfyUI/models
custom_nodes: |
  /opt/ComfyUI/custom_nodes
  /workspace/custom_nodes
user_dir: |
  /workspace/ComfyUI/user
clip: |
  /workspace/models/clip
  /opt/ComfyUI/models/clip
vae: |
  /workspace/models/vae
  /opt/ComfyUI/models/vae
loras: |
  /workspace/models/loras
  /opt/ComfyUI/models/loras
checkpoints: |
  /workspace/models/diffusion_models
  /opt/ComfyUI/models/diffusion_models
diffusion_models: |
  /workspace/models/diffusion_models
  /opt/ComfyUI/models/diffusion_models
YAML

if [[ "${ENABLE_JUPYTER:-true}" == "true" ]]; then
  nohup start-jupyter > /workspace/jupyter.log 2>&1 &
fi

if [[ -f "${MODELS_MANIFEST:-}" ]]; then
  nohup python - <<'PY' "${MODELS_MANIFEST}" "${MODELS_DIR:-/workspace/models}" "${HF_TOKEN:-}" > /workspace/models_download.log 2>&1 &
import sys, os
from huggingface_hub import hf_hub_download
mf, root, tok = sys.argv[1], sys.argv[2], (sys.argv[3] or None)
os.makedirs(root, exist_ok=True)
for line in open(mf, "r", encoding="utf-8"):
    line=line.strip()
    if not line or line.startswith("#"): continue
    try: repo, rel, sub = line.split("|", 3)
    except ValueError: 
        print("skip:", line); continue
    dstdir = os.path.join(root, sub); os.makedirs(dstdir, exist_ok=True)
    try:
        fp = hf_hub_download(repo_id=repo, filename=rel, token=tok, local_dir=dstdir, local_dir_use_symlinks=False)
        print("ok:", repo, rel, "->", fp)
    except Exception as e:
        print("fail:", repo, rel, "->", e)
PY
fi

exec start-comfyui
