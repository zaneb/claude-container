ARG FEDORA_VERSION=latest
FROM registry.fedoraproject.org/fedora:${FEDORA_VERSION}

RUN dnf install -y nodejs socat bubblewrap which procps-ng @development-tools jq golang python3

RUN mkdir -p /opt/npm-global && npm config set prefix /opt/npm-global
RUN npm install -g @anthropic-ai/claude-code --no-fund

COPY settings.json /etc/claude-code/managed-settings.json

RUN useradd -m claude
COPY sudoers /etc/sudoers.d/claude
USER claude:claude
RUN mkdir /home/claude/.config
WORKDIR /projects
ENV CLAUDE_CODE_USE_VERTEX=1 CLOUD_ML_REGION=us-east5 DISABLE_AUTOUPDATER=1
ENTRYPOINT ["/opt/npm-global/bin/claude"]
