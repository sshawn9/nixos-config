#!/usr/bin/env bash

set -euo pipefail

# Scientific computing, tabular data, analytical storage, and common file
# formats. Keep these broad groups stable; add a new group only when packages
# need a substantially different installation policy.
scientific_packages=(
  numpy
  scipy
  pandas
  polars
  pyarrow
  duckdb
  openpyxl
  h5py
  sympy
  scikit-learn
  statsmodels
  xarray
)

# Plotting and image processing.
plotting_packages=(
  matplotlib
  seaborn
  plotly
  pillow
  scikit-image
  opencv-python-headless
)

# Interactive inspection, debugging, and testing.
debugging_packages=(
  ipython
  ipdb
  debugpy
  rich
  pytest
  pytest-cov
  pytest-xdist
  hypothesis
)

# General scripting: HTTP, parsing, configuration, CLI, system automation, and
# database clients.
automation_packages=(
  requests
  httpx
  aiohttp
  beautifulsoup4
  lxml
  pydantic
  pyyaml
  python-dotenv
  orjson
  typer
  click
  psutil
  watchdog
  tenacity
  tqdm
  sqlalchemy
  aiosqlite
  "psycopg[binary]"
  pymysql
  redis
)

# Install every package group in one resolution transaction.
packages=(
  "${scientific_packages[@]}"
  "${plotting_packages[@]}"
  "${debugging_packages[@]}"
  "${automation_packages[@]}"
)

python="${1:-$(command -v python || true)}"

if [[ -z $python || ! -x $python ]]; then
  echo "python was not found; activate a Python environment or pass its path" >&2
  echo "usage: $0 [/path/to/python]" >&2
  exit 2
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is required to install Python wheels" >&2
  exit 127
fi

uv_args=(
  --python "$python"
  --no-managed-python
  --only-binary :all:
  --upgrade
  --compile-bytecode
)

# uv requires --system only when the selected interpreter is not a venv.
if "$python" -c 'import sys; raise SystemExit(sys.prefix != sys.base_prefix)'; then
  uv_args+=(--system)
fi

uv pip install "${uv_args[@]}" "${packages[@]}"
