ARG FEDORA_VERSION=latest
FROM registry.fedoraproject.org/fedora:${FEDORA_VERSION}

RUN dnf install -y wget2 jq socat bubblewrap

COPY packages.txt /opt/packages.txt
RUN dnf install -y $(cat /opt/packages.txt)

COPY settings.json /etc/claude-code/managed-settings.json

ARG UID=1000
ARG GID=1000
RUN groupadd -g "${GID}" claude && useradd -u "${UID}" -g "${GID}" -m claude
COPY sudoers /etc/sudoers.d/claude
USER claude:claude
ENV BASH_ENV=/home/claude/.bash_environment
COPY environment $BASH_ENV

ENV PATH=/home/claude/.local/bin:/usr/local/bin:/usr/bin
RUN curl -fsSL --proto-redir '-all,https' --tlsv1.3 https://claude.ai/install.sh | bash

RUN mkdir /home/claude/.config
WORKDIR /projects
ENV CLAUDE_CODE_USE_VERTEX=1 CLOUD_ML_REGION=us-east5 DISABLE_AUTOUPDATER=1
ENTRYPOINT ["/home/claude/.local/bin/claude"]
