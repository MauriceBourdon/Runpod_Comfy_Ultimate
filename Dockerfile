FROM nvidia/cuda:12.8.0-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive     PYTHONUNBUFFERED=1     PATH="/venv/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends     bash git git-lfs curl ca-certificates ffmpeg     python3 python3-venv python3-pip     tini libgl1 libglib2.0-0 jq rsync aria2     build-essential ninja-build python3-dev  && git lfs install  && rm -rf /var/lib/apt/lists/*

# Python env + PyTorch cu128 baked-in
RUN python3 -m venv /venv  && /venv/bin/pip install -U pip setuptools wheel packaging  && /venv/bin/pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cu128 torch  && /venv/bin/pip install --no-cache-dir jupyterlab==4.2.5 huggingface-hub==0.24.6 safetensors==0.4.5 pyyaml tqdm

# ComfyUI + requirements
RUN git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git /opt/ComfyUI  && /venv/bin/pip install --no-cache-dir -r /opt/ComfyUI/requirements.txt

# ComfyUI-Manager only
RUN git clone --depth=1 https://github.com/Comfy-Org/ComfyUI-Manager /opt/ComfyUI/custom_nodes/ComfyUI-Manager ||     git clone --depth=1 https://github.com/ltdrdata/ComfyUI-Manager /opt/ComfyUI/custom_nodes/ComfyUI-Manager  && if [ -f /opt/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt ]; then       /venv/bin/pip install --no-cache-dir -r /opt/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt;     fi

# SageAttention + Triton baked-in
RUN /venv/bin/pip install --no-cache-dir --upgrade triton ninja  && /venv/bin/pip install --no-cache-dir --no-binary=:all: sageattention

# Scripts + manifests + helper binaries
COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/download_models_async.sh /scripts/download_models_async.sh
COPY scripts/download_models_worker.py /scripts/download_models_worker.py
COPY bin/start-comfyui /usr/local/bin/start-comfyui
COPY bin/start-jupyter /usr/local/bin/start-jupyter
COPY bin/pull-models /usr/local/bin/pull-models
COPY manifests/ /manifests/

RUN chmod +x /entrypoint.sh /scripts/download_models_async.sh             /usr/local/bin/start-comfyui /usr/local/bin/start-jupyter             /usr/local/bin/pull-models

# Defaults
ENV ENABLE_JUPYTER=true     JUPYTER_PORT=8888     COMFY_AUTOSTART=true     COMFY_PORT=8188     COMFY_ARGS="--listen 0.0.0.0 --port 8188 --use-sage-attention"     DATA_DIR=/workspace     COMFY_DIR=/opt/ComfyUI     MODELS_DIR=/workspace/models     MODELS_MANIFEST=/workspace/models_manifest.txt     PIP_CACHE_DIR=/workspace/.pip-cache     PIP_NO_CACHE_DIR=0

EXPOSE 8188 8888
WORKDIR /opt/ComfyUI
ENTRYPOINT ["/usr/bin/tini","-s","--","bash","/entrypoint.sh"]
