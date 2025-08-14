FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1 TZ=UTC
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-venv python3-pip git git-lfs curl ca-certificates ffmpeg tini aria2 jq rsync net-tools iproute2 wget unzip build-essential python3-dev pkg-config cmake libgl1 libglib2.0-0 && git lfs install && rm -rf /var/lib/apt/lists/*
RUN python3 -m venv /venv && /venv/bin/pip install --no-cache-dir -U pip setuptools wheel
RUN /venv/bin/pip install --no-cache-dir jupyterlab==4.2.5 jupyterlab-lsp==5.1.0 jupyter-lsp==2.2.5
ARG COMFY_REPO=https://github.com/comfyanonymous/ComfyUI.git
ARG COMFY_REF=auto
ENV COMFY_REPO=${COMFY_REPO} COMFY_REF=${COMFY_REF}
RUN set -eux; if [ "${COMFY_REF}" = "auto" ] || [ -z "${COMFY_REF}" ]; then DEF_BRANCH="$(git ls-remote --symref "${COMFY_REPO}" HEAD | awk '/^ref:/ {print $2}' | sed 's|refs/heads/||')"; REF_TO_USE="${DEF_BRANCH}"; else REF_TO_USE="${COMFY_REF}"; fi; for i in 1 2 3; do if [ "${REF_TO_USE#refs/}" != "${REF_TO_USE}" ] || [ ${#REF_TO_USE} -eq 40 ]; then git clone --depth=1 "${COMFY_REPO}" /opt/ComfyUI && git -C /opt/ComfyUI checkout -q "${REF_TO_USE}" && break; else git clone --depth=1 --branch "${REF_TO_USE}" "${COMFY_REPO}" /opt/ComfyUI && break; fi; sleep 10; rm -rf /opt/ComfyUI || true; done; if [ ! -d /opt/ComfyUI ]; then mkdir -p /opt/ComfyUI && cd /opt/ComfyUI; case "${REF_TO_USE}" in ????????????????????????????????????????) REF_DL="master" ;; *) REF_DL="${REF_TO_USE}" ;; esac; curl -fL "https://codeload.github.com/comfyanonymous/ComfyUI/tar.gz/${REF_DL}" | tar -xz --strip-components=1; fi; test -f /opt/ComfyUI/main.py
RUN git clone --depth=1 https://github.com/Comfy-Org/ComfyUI-Manager /opt/ComfyUI/custom_nodes/ComfyUI-Manager && if [ -f /opt/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt ]; then /venv/bin/pip install --no-cache-dir -r /opt/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt; fi
RUN mkdir -p /workspace /manifests /scripts /opt/ComfyUI/user/default/workflows /usr/local/bin /workspace/models
COPY scripts/ /scripts/
COPY bin/ /usr/local/bin/
COPY manifests/ /manifests/
RUN chmod +x /usr/local/bin/* /scripts/*.sh
ENV ENABLE_JUPYTER=true JUPYTER_PORT=8888 JUPYTER_DIR=/workspace COMFY_AUTOSTART=true COMFY_PORT=8188 COMFY_ARGS="--listen 0.0.0.0 --port 8188 --use-sage-attention" DATA_DIR=/workspace COMFY_DIR=/opt/ComfyUI MODELS_DIR=/workspace/models COMFY_WORKFLOWS_SRC=/workspace/workflows COMFY_WORKFLOWS_MODE=symlink CUSTOM_NODES_MANIFEST=/manifests/nodes_manifest.txt MODELS_MANIFEST=/manifests/models_manifest.txt WORKFLOWS_MANIFEST=/manifests/workflows_manifest.txt NODES_INSTALL_MODE=sync COMFY_UPDATE_AT_START=false COMFY_REF_RUNTIME= TORCH_INDEX_URL=https://download.pytorch.org/whl/cu128 TORCH_SPEC_TORCH=torch TORCH_SPEC_VISION=torchvision TORCH_SPEC_AUDIO=torchaudio PIP_CACHE_DIR=/workspace/.pip-cache PIP_NO_CACHE_DIR=0
HEALTHCHECK --start-period=60s --interval=30s --timeout=5s CMD bash -lc 'curl -fsS http://127.0.0.1:${COMFY_PORT:-8188}/ >/dev/null && curl -fsS http://127.0.0.1:${JUPYTER_PORT:-8888}/lab >/dev/null || exit 1'
WORKDIR /opt/ComfyUI
ENTRYPOINT ["/usr/bin/tini", "--", "/scripts/entrypoint.sh"]
