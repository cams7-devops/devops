FROM debian:buster-slim
ARG GITHUB_RUNNER_VERSION="2.284.0"
ARG DOCKER_VERSION="20.10.10"

ENV GITHUB_PAT ""
ENV GITHUB_OWNER ""
ENV GITHUB_REPOSITORY ""
ENV RUNNER_WORKDIR "/home/github/_work"
ENV RUNNER_LABELS ""
ENV DOCKER_HOST ""

RUN apt-get update -y
RUN apt-get install -y curl sudo git jq iputils-ping tar gnupg2 apt-transport-https ca-certificates unzip
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*
    
RUN useradd -m github && usermod -aG sudo github && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN curl https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz --output docker-$DOCKER_VERSION.tgz
RUN tar xvfz ./docker-$DOCKER_VERSION.tgz
RUN cp docker/* /usr/bin/
RUN rm docker-$DOCKER_VERSION.tgz

RUN curl https://dlcdn.apache.org/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz --output apache-maven-3.8.4-bin.tar.gz
RUN tar -xvf ./apache-maven-3.8.4-bin.tar.gz -C /usr/share/
RUN ln -s /usr/share/apache-maven-3.8.4/bin/mvn /usr/bin/mvn
RUN echo "M2_HOME=/usr/share/apache-maven-3.8.4" | tee -a /etc/environment
RUN rm apache-maven-3.8.4-bin.tar.gz

RUN curl https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.6.2.2472-linux.zip --output sonar-scanner-cli-4.6.2.2472-linux.zip
RUN unzip ./sonar-scanner-cli-4.6.2.2472-linux.zip -d /usr/share/
RUN ln -s /usr/share/sonar-scanner-4.6.2.2472-linux/bin/sonar-scanner /usr/bin/sonar-scanner
RUN ln -s /usr/share/sonar-scanner-4.6.2.2472-linux/bin/sonar-scanner-debug /usr/bin/sonar-scanner-debug
RUN rm sonar-scanner-cli-4.6.2.2472-linux.zip

USER github
WORKDIR /home/github

RUN curl -O -L https://github.com/actions/runner/releases/download/v$GITHUB_RUNNER_VERSION/actions-runner-linux-x64-$GITHUB_RUNNER_VERSION.tar.gz
RUN tar xzf ./actions-runner-linux-x64-$GITHUB_RUNNER_VERSION.tar.gz
RUN rm actions-runner-linux-x64-$GITHUB_RUNNER_VERSION.tar.gz
RUN sudo ./bin/installdependencies.sh

COPY --chown=github:github entrypoint.sh ./entrypoint.sh
RUN sudo chmod u+x ./entrypoint.sh

ENTRYPOINT ["/home/github/entrypoint.sh"]
