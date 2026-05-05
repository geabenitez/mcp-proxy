# Build stage with explicit platform specification
FROM ghcr.io/astral-sh/uv:python3.13-alpine AS uv

# Install the project into /app
WORKDIR /app

# Enable bytecode compilation
ARG UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ARG UV_LINK_MODE=copy

# Install the project's dependencies using the lockfile and settings
COPY uv.lock pyproject.toml /app/
RUN --mount=type=cache,id=s/164538f8-e1be-4336-a61c-45238d62d800-/root/.cache/uv,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev --no-editable

# Then, add the rest of the project source code and install it
# Installing separately from its dependencies allows optimal layer caching
COPY . /app
RUN --mount=type=cache,id=s/164538f8-e1be-4336-a61c-45238d62d800-/root/.cache/uv,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

RUN apk add --update --no-cache catatonit

# Final stage with explicit platform specification
FROM python:3.13-alpine

COPY --from=uv --chown=app:app /app/.venv /app/.venv
COPY --from=uv /usr/bin/catatonit /usr/bin/
COPY --from=uv /usr/libexec/podman/catatonit /usr/libexec/podman/

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

ENTRYPOINT ["catatonit", "--", "mcp-proxy"]
