FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV UV_NO_CACHE=1

COPY --from=ghcr.io/astral-sh/uv:0.12.24 /uv /uvx /bin/

RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . /app

RUN uv pip install --system \
        --index-url https://download.pytorch.org/whl/cpu torch && \
    uv pip install --system -e . --no-deps && \
    uv pip install --system numba numpy tqdm more-itertools tiktoken

CMD ["python", "-m", "whisper", "--help"]
