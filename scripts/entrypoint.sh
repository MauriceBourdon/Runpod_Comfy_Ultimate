\
#!/usr/bin/env bash
set -euo pipefail

export PATH="/venv/bin:$PATH"

DATA_DIR="${DATA_DIR:-/workspace}"
COMFY_DIR="${COMFY_DIR:-/opt/ComfyUI}"
MODELS_DIR="${MODELS_DIR:-/workspace/models}"
MODELS_MANIFEST="${MODELS_MANIFEST:-/workspace/models_manifest.txt}"

# Ensure core dirs exist
mkdir -p "${DATA_DIR}" "${MODELS_DIR}"/{diffusion_models,vae,loras,clip,controlnet}
mkdir -p "${COMFY_DIR}/user/default/workflows" "${COMFY_DIR}/input" "${COMFY_DIR}/output"

# v4.1.3-compatible extra_model_paths.yaml
cat >"${COMFY_DIR}/extra_model_paths.yaml" <<'YAML'
models:
  diffusion_models: /workspace/models/diffusion_models
  vae: /workspace/models/vae
  loras: /workspace/models/loras
  clip: /workspace/models/clip
  controlnet: /workspace/models/controlnet
YAML

# Symlinks in /workspace (no nested ComfyUI/ComfyUI)
ln -sfnT "${COMFY_DIR}" "${DATA_DIR}/ComfyUI"
ln -sfnT "${COMFY_DIR}/user/default/workflows" "${DATA_DIR}/workflows"
ln -sfnT "${COMFY_DIR}/input" "${DATA_DIR}/input"
ln -sfnT "${COMFY_DIR}/output" "${DATA_DIR}/output"

# If no user manifest present, seed it from /manifests (once)
if [[ ! -f "${MODELS_MANIFEST}" && -f "/manifests/models_manifest.txt" ]]; then
  cp -n "/manifests/models_manifest.txt" "${MODELS_MANIFEST}"
fi

# Start Jupyter (optional)
if [[ "${ENABLE_JUPYTER:-true}" == "true" ]]; then
  nohup /usr/local/bin/start-jupyter > "${DATA_DIR}/jupyter.log" 2>&1 &
fi

# Models download (async) via bash
if [[ -f "${MODELS_MANIFEST}" ]]; then
  nohup bash /scripts/download_models_async.sh \
    "${MODELS_MANIFEST}" "${MODELS_DIR}" \
    > "${DATA_DIR}/models_download.log" 2>&1 &
fi

# Start ComfyUI
exec /usr/local/bin/start-comfyui
