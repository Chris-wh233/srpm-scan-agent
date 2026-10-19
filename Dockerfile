FROM lcr.loongnix.cn/library/openjdk:21-jdk

ARG JENKINS_AGENT_JAR_URL

ENV HOME=/home/jenkins \
    JENKINS_AGENT_WORKDIR=/home/jenkins/agent

USER root

RUN printf '%s\n' \
      'deb http://mirrors.ustc.edu.cn/debian unstable main' \
      > /etc/apt/sources.list && \
    rm -f /etc/apt/sources.list.d/debian.sources && \
    apt-get -o Acquire::Retries=5 update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      coreutils \
      curl \
      gzip \
      python3 \
      tar \
      util-linux \
      xz-utils && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/share/jenkins && \
    curl --fail --location --retry 5 \
      --output /usr/share/jenkins/agent.jar \
      "${JENKINS_AGENT_JAR_URL}"

ARG AGENT_UID=1000
ARG AGENT_GID=1000
RUN groupadd --gid ${AGENT_GID} jenkins && \
    useradd --uid ${AGENT_UID} --gid ${AGENT_GID} --create-home --shell /bin/bash jenkins && \
    mkdir -p /home/jenkins/agent && \
    chown -R jenkins:jenkins /home/jenkins

COPY scripts/run-srpm-scan /usr/local/bin/run-srpm-scan
COPY scripts/send-srpm-event /usr/local/bin/send-srpm-event
COPY scripts/jenkins-agent-entrypoint /usr/local/bin/jenkins-agent-entrypoint

RUN chmod 0755 \
      /usr/local/bin/run-srpm-scan \
      /usr/local/bin/send-srpm-event \
      /usr/local/bin/jenkins-agent-entrypoint

USER jenkins
WORKDIR /home/jenkins/agent

ENTRYPOINT ["jenkins-agent-entrypoint"]
