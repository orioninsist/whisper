FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV UV_NO_CACHE=1
ENV UV_LINK_MODE=copy

COPY --from=ghcr.io/astral-sh/uv:0.12.24 /uv /uvx /bin/

RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY pyproject.toml uv.lock README.md ./
COPY whisper ./whisper

RUN mkdir -p /app/.local/kokoro/spacy

RUN --mount=type=bind,from=spacywheel,source=en_core_web_sm-3.8.0-py3-none-any.whl,target=/app/.local/kokoro/spacy/en_core_web_sm-3.8.0-py3-none-any.whl,readonly \
    uv sync --locked --no-default-groups --no-editable

CMD ["/app/.venv/bin/python", "-m", "whisper", "--help"]
