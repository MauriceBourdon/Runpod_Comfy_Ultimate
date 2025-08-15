FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive PYTHONUNBUFFERED=1 PATH="/venv/bin:$PATH"
RUN apt-get update && apt-get install -y --no-install-recommends bash git git-lfs curl ca-certificates ffmpeg python3 python3-venv python3-pip tini libgl1 libglib2.0-0 jq rsync && git lfs install && rm -rf /var/lib/apt/lists/*
RUN python3 -m venv /venv && pip install -U pip setuptools wheel && pip install jupyterlab==4.2.5
RUN git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git /opt/ComfyUI
RUN git clone --depth=1 https://github.com/Comfy-Org/ComfyUI-Manager /opt/ComfyUI/custom_nodes/ComfyUI-Manager || git clone --depth=1 https://github.com/ltdrdata/ComfyUI-Manager /opt/ComfyUI/custom_nodes/ComfyUI-Manager
COPY scripts/entrypoint.sh /entrypoint.sh
COPY bin/start-comfyui /usr/local/bin/start-comfyui
COPY bin/start-jupyter /usr/local/bin/start-jupyter
COPY manifests/ /manifests/
RUN chmod +x /entrypoint.sh /usr/local/bin/start-comfyui /usr/local/bin/start-jupyter
ENV ENABLE_JUPYTER=true JUPYTER_PORT=8888 COMFY_AUTOSTART=true COMFY_PORT=8188 COMFY_ARGS="--listen 0.0.0.0 --port 8188 --use-sage-attention" DATA_DIR=/workspace COMFY_DIR=/opt/ComfyUI MODELS_DIR=/workspace/models MODELS_MANIFEST=/manifests/models_manifest.txt PIP_CACHE_DIR=/workspace/.pip-cache PIP_NO_CACHE_DIR=0
EXPOSE 8188 8888
WORKDIR /opt/ComfyUI
ENTRYPOINT ["/usr/bin/tini","-s","--","bash","/entrypoint.sh"]
