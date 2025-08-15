\
#!/usr/bin/env bash
set -euo pipefail
MF="${1:-/manifests/models_manifest.txt}"
ROOT="${2:-/workspace/models}"
export PATH="/venv/bin:$PATH"
exec python /scripts/download_models_worker.py --manifest "$MF" --out "$ROOT"
