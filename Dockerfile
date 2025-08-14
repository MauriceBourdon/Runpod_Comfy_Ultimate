FROM nvidia/cuda:12.8.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive     PYTHONUNBUFFERED=1     VENV_PATH=/venv     PATH="/venv/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends     git wget curl python3 python3-venv python3-pip ffmpeg libgl1 ca-certificates tini jq rsync  && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv $VENV_PATH && $VENV_PATH/bin/pip install --no-cache-dir -U pip wheel setuptools  && $VENV_PATH/bin/pip install --no-cache-dir jupyterlab==4.2.5

WORKDIR /opt

ARG COMFY_REPO=https://github.com/comfyanonymous/ComfyUI.git
ARG COMFY_REF=master
ENV COMFY_REPO=${COMFY_REPO} COMFY_REF=${COMFY_REF}

RUN git clone --depth=1 --branch ${COMFY_REF} ${COMFY_REPO} /opt/ComfyUI

# Pre-install Manager
RUN git clone --depth=1 https://github.com/Comfy-Org/ComfyUI-Manager /opt/ComfyUI/custom_nodes/ComfyUI-Manager ||     git clone --depth=1 https://github.com/ltdrdata/ComfyUI-Manager /opt/ComfyUI/custom_nodes/ComfyUI-Manager

# Torch/cu128 installed at runtime (entrypoint) to reduce image weight and avoid build-time failures.

COPY scripts/entrypoint.sh /entrypoint.sh
COPY bin/start-comfyui /usr/local/bin/start-comfyui
COPY bin/start-jupyter /usr/local/bin/start-jupyter
COPY manifests/ /manifests/

RUN chmod +x /entrypoint.sh /usr/local/bin/start-comfyui /usr/local/bin/start-jupyter

ENV ENABLE_JUPYTER=true     JUPYTER_PORT=8888     JUPYTER_TOKEN=     COMFY_AUTOSTART=true     COMFY_PORT=8188     COMFY_ARGS="--listen 0.0.0.0 --port 8188 --use-sage-attention"     DATA_DIR=/workspace     COMFY_DIR=/opt/ComfyUI     MODELS_DIR=/workspace/models     COMFY_WORKFLOWS_SRC=/workspace/workflows     COMFY_WORKFLOWS_MODE=symlink     CUSTOM_NODES_MANIFEST=/manifests/nodes.txt     MODELS_MANIFEST=/manifests/models_all.txt     WORKFLOWS_MANIFEST=/manifests/workflows_all.txt     NODES_INSTALL_MODE=sync     PIP_CACHE_DIR=/workspace/.pip-cache     PIP_NO_CACHE_DIR=0

EXPOSE 8188 8888
ENTRYPOINT ["/usr/bin/tini","--","/entrypoint.sh"]
