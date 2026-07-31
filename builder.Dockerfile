# CI builder image for Godot projects: barichello/godot-ci (editor + web
# export templates) with make/zip preinstalled, so the pipeline's build step
# does not run apt-get on every run.
#
# Keep the tag in sync with the Godot version the projects use.
#
# Build & push (the CI runner is linux/amd64):
#   docker build --platform linux/amd64 -f builder.Dockerfile \
#     --build-arg GODOT_VERSION=4.6 \
#     -t git.teletypegames.org/internal/godot-builder:4.6 .
#   docker push git.teletypegames.org/internal/godot-builder:4.6

ARG GODOT_VERSION=4.6
FROM barichello/godot-ci:${GODOT_VERSION}

RUN apt-get update \
 && apt-get install -y --no-install-recommends make zip jq \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
