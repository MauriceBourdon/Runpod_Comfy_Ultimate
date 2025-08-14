\
#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[$(date -u +'%F %T')] $*"; }

export PATH="/venv/bin:$PATH"
mkdir -p "${DATA_DIR:-/workspace}" "${MODELS_DIR:-/workspace/models}" "${COMFY_WORKFLOWS_SRC:-/workspace/workflows}" /workspace/custom_nodes "${PIP_CACHE_DIR:-/workspace/.pip-cache}"

if [[ -z "${JUPYTER_TOKEN:-}" && -n "${JUPYTER_TOKEN_FILE:-}" && -r "${JUPYTER_TOKEN_FILE}" ]]; then
  export JUPYTER_TOKEN="$(cat "${JUPYTER_TOKEN_FILE}")"
fi

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

diffusion_models: |
  /workspace/models/diffusion_models
  /opt/ComfyUI/models/diffusion_models
YAML

if ! python -c "import torch" >/dev/null 2>&1; then
  log "Installing torch/cu128 wheels..."
  python -m pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cu128 torch torchvision torchaudio || \
  (log "CUDA wheels not available, fallback to CPU" && python -m pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu torch torchvision torchaudio)
fi
python -m pip install --no-cache-dir huggingface-hub diffusers accelerate safetensors einops timm peft ftfy sentencepiece protobuf

install_nodes(){
  local file="${1:-}"; local dest="${COMFY_DIR:-/opt/ComfyUI}/custom_nodes"
  [[ -f "$file" ]] || { log "no nodes file: $file"; return 0; }
  mkdir -p "$dest"
  while IFS= read -r repo; do
    [[ -z "$repo" || "$repo" =~ ^# ]] && continue
    local name="$(basename "$repo")"; local dir="$dest/$name"
    if [[ -d "$dir/.git" ]]; then git -C "$dir" pull --ff-only || true
    else git clone --depth=1 "$repo" "$dir" || true
    fi
    [[ -f "$dir/requirements.txt" ]] && python -m pip install -r "$dir/requirements.txt" || true
  done < "$file"
}

download_models(){
  local file="${1:-}"
  [[ -f "$file" ]] || { log "no models file: $file"; return 0; }
  python - <<'PY' "$file" "${MODELS_DIR:-/workspace/models}" "${HF_TOKEN:-}"
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
}

manage_workflows(){
  local file="${1:-}" src="${COMFY_WORKFLOWS_SRC:-/workspace/workflows}" dst="${COMFY_DIR:-/opt/ComfyUI}/user/default/workflows"
  mkdir -p "$src" "$dst"
  [[ -f "$file" ]] && while IFS= read -r url; do
    [[ -z "$url" || "$url" =~ ^# ]] && continue
    curl -fsSL "$url" -o "$src/$(basename "$url")" || true
  done < "$file"
  if [[ "${COMFY_WORKFLOWS_MODE:-symlink}" == "symlink" ]]; then
    for f in "$src"/*.json; do [[ -e "$f" ]] || continue; ln -sf "$f" "$dst/$(basename "$f")"; done
  else
    rsync -a --delete "$src/". "$dst/"
  fi
}

if [[ -f "${CUSTOM_NODES_MANIFEST:-}" ]]; then install_nodes "${CUSTOM_NODES_MANIFEST}"; fi
if [[ -f "${MODELS_MANIFEST:-}" ]]; then download_models "${MODELS_MANIFEST}" & fi
if [[ -f "${WORKFLOWS_MANIFEST:-}" ]]; then manage_workflows "${WORKFLOWS_MANIFEST}"; fi

if [[ "${ENABLE_JUPYTER:-true}" == "true" ]]; then
  nohup jupyter lab --ServerApp.ip=0.0.0.0 --ServerApp.port="${JUPYTER_PORT:-8888}" --ServerApp.open_browser=False --ServerApp.token="${JUPYTER_TOKEN:-}" --ServerApp.password='' --ServerApp.allow_origin='*' --ServerApp.root_dir="/workspace" --ServerApp.allow_root=True > /workspace/jupyter.log 2>&1 &
fi

exec start-comfyui
