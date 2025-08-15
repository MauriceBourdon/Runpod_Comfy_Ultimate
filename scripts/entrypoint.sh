\
#!/usr/bin/env bash
set -euo pipefail

export PATH="/venv/bin:$PATH"

mkdir -p "${DATA_DIR:-/workspace}" "${MODELS_DIR:-/workspace/models}" "${PIP_CACHE_DIR:-/workspace/.pip-cache}" \
         "${COMFY_DIR:-/opt/ComfyUI}/user/default/workflows"

# Generate extra_model_paths.yaml (multi-line scalars)
cat >"${COMFY_DIR:-/opt/ComfyUI}/extra_model_paths.yaml" <<'YAML'
checkpoint: |
  /workspace/models/diffusion_models
  /opt/ComfyUI/models/checkpoints

diffusion_models: |
  /workspace/models/diffusion_models
  /opt/ComfyUI/models/diffusion_models

lora: |
  /workspace/models/loras
  /opt/ComfyUI/models/loras

vae: |
  /workspace/models/vae
  /opt/ComfyUI/models/vae

clip: |
  /workspace/models/clip
  /opt/ComfyUI/models/clip
YAML

# Start Jupyter (optional)
if [[ "${ENABLE_JUPYTER:-true}" == "true" ]]; then
  nohup /usr/local/bin/start-jupyter > /workspace/jupyter.log 2>&1 &
fi

# Async download models from manifest (HF public or private via HF_TOKEN)
if [[ -f "${MODELS_MANIFEST:-}" ]]; then
  nohup python - <<'PY' "${MODELS_MANIFEST}" "${MODELS_DIR:-/workspace/models}" "${HF_TOKEN:-}" > /workspace/models_download.log 2>&1 &
import sys, os
from huggingface_hub import hf_hub_download
mf, root, tok = sys.argv[1], sys.argv[2], (sys.argv[3] or None)
os.makedirs(root, exist_ok=True)
for line in open(mf, "r", encoding="utf-8"):
    line=line.strip()
    if not line or line.startswith("#"): continue
    try:
        repo, rel, sub = line.split("|", 3)
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

# Launch ComfyUI
exec /usr/local/bin/start-comfyui
