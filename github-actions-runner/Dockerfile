FROM debian:stretch-slim
ARG RUNNER_VERSION="2.284.0"

ENV GITHUB_PERSONAL_TOKEN ""
ENV GITHUB_OWNER ""
ENV GITHUB_REPOSITORY ""

RUN apt-get update -y
RUN apt-get install -y curl sudo git jq tar gnupg2 apt-transport-https ca-certificates
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*
    
RUN useradd -m github-actions-runner && usermod -aG sudo github-actions-runner && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER github-actions-runner
WORKDIR /home/github-actions-runner

RUN curl -O -L https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
RUN tar xzf ./actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
RUN rm actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
RUN sudo ./bin/installdependencies.sh

COPY --chown=github-actions-runner:github-actions-runner entrypoint.sh ./entrypoint.sh
RUN sudo chmod u+x ./entrypoint.sh

ENTRYPOINT ["/home/github-actions-runner/entrypoint.sh"]
