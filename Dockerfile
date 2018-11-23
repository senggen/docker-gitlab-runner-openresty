FROM openresty/openresty:centos

RUN curl -fsSL https://get.docker.com/ | sh && \
    systemctl enable docker && \
    yum clean all

RUN curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | bash && \
    yum -y install gitlab-runner wget && \
    yum clean all && \
    wget -qO /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 && \
    chmod +x /usr/bin/dumb-init
    
ADD run.sh /home
RUN chmod +x /home/run.sh

WORKDIR /home/gitlab-runner
    
CMD /home/run.sh
