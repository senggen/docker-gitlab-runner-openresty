FROM senggen/openresty

# Docker
RUN curl -fsSL get.docker.com -o get-docker.sh && \
    sh get-docker.sh --mirror Aliyun && \
    systemctl enable docker && \
    rm get-docker.sh && \
    yum clean all

# Gitlab Runner
RUN curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | bash && \
    yum -y install gitlab-runner && \
    yum clean all

ADD run.sh /home
RUN chmod +x /home/run.sh && \
    chmod a+rw -R $NGX_ROOT

WORKDIR /home/gitlab-runner

CMD /home/run.sh
