ARG FEDORA_VERSION=latest
FROM registry.fedoraproject.org/fedora:${FEDORA_VERSION}

RUN dnf install -y nodejs @development-tools golang python3 && dnf clean all && rm -rf /var/cache/{yum,dnf}/*

RUN mkdir -p /opt/npm-global && npm config set prefix /opt/npm-global
RUN npm install -g @anthropic-ai/claude-code --no-fund

RUN useradd -m claude
USER claude:claude
WORKDIR /projects
ENV CLAUDE_CODE_USE_VERTEX=1 CLOUD_ML_REGION=us-east5
ENTRYPOINT ["/opt/npm-global/bin/claude"]
