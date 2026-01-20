ARG FEDORA_VERSION=latest
FROM registry.fedoraproject.org/fedora:${FEDORA_VERSION}

RUN dnf install -y nodejs socat bubblewrap

RUN mkdir -p /opt/npm-global && npm config set prefix /opt/npm-global
RUN npm config set ignore-scripts true
RUN npm install -g @anthropic-ai/claude-code --no-fund

COPY packages.txt /opt/packages.txt
RUN dnf install -y $(cat /opt/packages.txt)

COPY settings.json /etc/claude-code/managed-settings.json

ARG UID=1000
ARG GID=1000
RUN groupadd -f -g "${GID}" claude && (id -u "${UID}" &>/dev/null || useradd -u "${UID}" -g "${GID}" -m claude)
COPY sudoers /etc/sudoers.d/claude
RUN chmod 0440 /etc/sudoers.d/claude
USER claude:${GID}
ENV BASH_ENV=/home/claude/.bash_environment
COPY environment $BASH_ENV
WORKDIR /projects
ENV CLAUDE_CODE_USE_VERTEX=1 CLOUD_ML_REGION=us-east5 DISABLE_AUTOUPDATER=1
ENTRYPOINT ["/opt/npm-global/bin/claude"]
