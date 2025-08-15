\
#!/usr/bin/env bash
set -euo pipefail

export PATH="/venv/bin:$PATH"

mkdir -p "${DATA_DIR:-/workspace}" \
         "${MODELS_DIR:-/workspace/models}" \
         "${PIP_CACHE_DIR:-/workspace/.pip-cache}" \
         "${COMFY_DIR:-/opt/ComfyUI}/user/default/workflows"

# v4.1.3-compatible extra_model_paths.yaml
cat >"${COMFY_DIR:-/opt/ComfyUI}/extra_model_paths.yaml" <<'YAML'
models:
  diffusion_models: /workspace/models/diffusion_models
  vae: /workspace/models/vae
  loras: /workspace/models/loras
  clip: /workspace/models/clip
  controlnet: /workspace/models/controlnet
YAML

# Jupyter (optional)
if [[ "${ENABLE_JUPYTER:-true}" == "true" ]]; then
  nohup /usr/local/bin/start-jupyter > /workspace/jupyter.log 2>&1 &
fi

# Models download (async)
if [[ -f "${MODELS_MANIFEST:-}" ]]; then
  nohup /scripts/download_models_async.sh "${MODELS_MANIFEST}" "${MODELS_DIR:-/workspace/models}" > /workspace/models_download.log 2>&1 &
fi

# Start ComfyUI
exec /usr/local/bin/start-comfyui
