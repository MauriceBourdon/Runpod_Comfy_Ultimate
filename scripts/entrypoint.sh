#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -u +'%F %T')] $*"; }

# Secrets via fichiers
if [[ -z "${JUPYTER_TOKEN:-}" && -n "${JUPYTER_TOKEN_FILE:-}" && -r "${JUPYTER_TOKEN_FILE}" ]]; then
  export JUPYTER_TOKEN="$(cat "${JUPYTER_TOKEN_FILE}")"
fi
if [[ -z "${HF_TOKEN:-}" && -n "${HF_TOKEN_FILE:-}" && -r "${HF_TOKEN_FILE}" ]]; then
  export HF_TOKEN="$(cat "${HF_TOKEN_FILE}")"
fi

# Update ComfyUI au boot (optionnel)
if [[ "${COMFY_UPDATE_AT_START:-false}" == "true" && -n "${COMFY_REF_RUNTIME:-}" ]]; then
  log "Updating ComfyUI to ${COMFY_REF_RUNTIME} ..."
  git -C "${COMFY_DIR:-/opt/ComfyUI}" fetch --all --tags || true
  git -C "${COMFY_DIR:-/opt/ComfyUI}" reset --hard "${COMFY_REF_RUNTIME}" || true
fi

# Chemins modèles + extra_model_paths.yaml robuste
mkdir -p "${MODELS_DIR:-/workspace/models}"/{diffusion_models,vae,clip,loras,controlnet,unet,upscale_models,ipadapter}
cat > "${COMFY_DIR:-/opt/ComfyUI}/extra_model_paths.yaml" <<YAML
diffusion_models: ${MODELS_DIR:-/workspace/models}/diffusion_models
vae: ${MODELS_DIR:-/workspace/models}/vae
clip: ${MODELS_DIR:-/workspace/models}/clip
loras: ${MODELS_DIR:-/workspace/models}/loras
controlnet: ${MODELS_DIR:-/workspace/models}/controlnet
unet: ${MODELS_DIR:-/workspace/models}/unet
upscale_models: ${MODELS_DIR:-/workspace/models}/upscale_models
ipadapter: ${MODELS_DIR:-/workspace/models}/ipadapter
YAML

# Jupyter (background)
if [[ "${ENABLE_JUPYTER:-true}" == "true" ]]; then
  log "Launching JupyterLab on ${JUPYTER_PORT:-8888} ..."
  nohup /venv/bin/jupyter lab \
    --ServerApp.ip=0.0.0.0 \
    --ServerApp.port="${JUPYTER_PORT:-8888}" \
    --ServerApp.open_browser=False \
    --ServerApp.token="${JUPYTER_TOKEN:-}" \
    --ServerApp.password='' \
    --ServerApp.allow_origin='*' \
    --ServerApp.root_dir="${JUPYTER_DIR:-/workspace}" \
    --ServerApp.allow_root=True \
    > "${JUPYTER_DIR:-/workspace}"/jupyter.log 2>&1 &
fi

# Torch au runtime (CUDA d'abord, CPU fallback)
if ! /venv/bin/python -c "import torch" >/dev/null 2>&1; then
  log "[torch] not found → installing CUDA wheels..."
  if ! /venv/bin/pip install --no-cache-dir \
        --index-url "${TORCH_INDEX_URL:-https://download.pytorch.org/whl/cu128}" \
        "${TORCH_SPEC_TORCH:-torch}" "${TORCH_SPEC_VISION:-torchvision}" "${TORCH_SPEC_AUDIO:-torchaudio}"; then
    log "[torch] CUDA wheels unavailable → CPU fallback"
    /venv/bin/pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu \
      torch torchvision torchaudio
  fi
else
  log "[torch] already installed."
fi

# Install nodes (sync/async)
install_nodes() {
  local manifest="${1:-}"; local custom_dir="${COMFY_DIR:-/opt/ComfyUI}/custom_nodes"
  [[ -f "$manifest" ]] || { log "no nodes manifest"; return 0; }
  mkdir -p "$custom_dir"
  while IFS= read -r repo; do
    [[ -z "$repo" || "$repo" =~ ^# ]] && continue
    name="$(basename "$repo")"; dest="${custom_dir}/${name}"
    if [[ -d "$dest/.git" ]]; then
      log "[nodes] update $name"; git -C "$dest" pull --ff-only || true
    else
      log "[nodes] clone $name"; git clone --depth=1 "$repo" "$dest" || true
    fi
    if [[ -f "$dest/requirements.txt" ]]; then
      /venv/bin/pip install -r "$dest/requirements.txt" || true
    fi
  done < "$manifest"
}

if [[ -f "${CUSTOM_NODES_MANIFEST:-}" ]]; then
  if [[ "${NODES_INSTALL_MODE:-sync}" == "sync" ]]; then
    install_nodes "${CUSTOM_NODES_MANIFEST}"
  else
    nohup bash -c "install_nodes \"${CUSTOM_NODES_MANIFEST}\"" >/workspace/nodes_install.log 2>&1 &
  fi
fi

# Workflows (download puis link/copy)
manage_workflows() {
  local src="${COMFY_WORKFLOWS_SRC:-/workspace/workflows}"
  local dst="${COMFY_DIR:-/opt/ComfyUI}/user/default/workflows"
  local mode="${COMFY_WORKFLOWS_MODE:-symlink}"
  mkdir -p "$src" "$dst"
  if [[ -n "${WORKFLOWS_MANIFEST:-}" && -f "${WORKFLOWS_MANIFEST}" ]]; then
    while IFS= read -r url; do
      [[ -z "$url" || "$url" =~ ^# ]] && continue
      fname="$(basename "$url")"
      curl -fsSL "$url" -o "${src}/${fname}" || true
    done < "${WORKFLOWS_MANIFEST}"
  fi
  if [[ "${mode}" == "symlink" ]]; then
    for f in "${src}"/*.json; do [[ -e "$f" ]] || continue; ln -sf "$f" "${dst}/$(basename "$f")"; done
  else
    rsync -a --delete "${src}/" "${dst}/"
  fi
}
manage_workflows

# Modèles (HF) en tâche de fond
if [[ -f "${MODELS_MANIFEST:-}" ]]; then
  nohup /venv/bin/python - <<'PY' "${MODELS_MANIFEST}" "${MODELS_DIR:-/workspace/models}" "${HF_TOKEN:-}" >/workspace/models_download.log 2>&1 &
import sys, os
from huggingface_hub import hf_hub_download
manifest, dest_root, token = sys.argv[1], sys.argv[2], (sys.argv[3] or None)
os.makedirs(dest_root, exist_ok=True)
for line in open(manifest, "r", encoding="utf-8"):
    line=line.strip()
    if not line or line.startswith("#"): continue
    try:
        repo, path, sub = line.split("|", 3)
    except ValueError:
        print("[models] skip invalid line:", line); continue
    dstdir = os.path.join(dest_root, sub); os.makedirs(dstdir, exist_ok=True)
    try:
        fp = hf_hub_download(repo_id=repo, filename=path, token=token,
                             local_dir=dstdir, local_dir_use_symlinks=False)
        print("[models] ok:", repo, path, "->", fp)
    except Exception as e:
        print("[models] fail:", repo, path, "->", e)
PY
fi

# Lancement ComfyUI
if [[ "${COMFY_AUTOSTART:-true}" == "true" ]]; then
  log "Starting ComfyUI ..."
  exec /usr/local/bin/start-comfyui
else
  log "COMFY_AUTOSTART=false; container is up."
  tail -f /dev/null
fi
