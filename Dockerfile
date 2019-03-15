FROM openresty/openresty:centos

RUN yum -y install lua lua-devel unzip wget make gcc && \
    wget http://luarocks.org/releases/luarocks-3.0.4.tar.gz && \
    tar -xzvf luarocks-3.0.4.tar.gz && \
    cd luarocks-3.0.4/ && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf luarocks-3.0.4 && \
    rm luarocks-3.0.4.tar.gz && \
    /usr/local/bin/luarocks install luacheck && \
    /usr/local/bin/luarocks install cluacov && \
    yum clean all

RUN curl -fsSL https://get.docker.com/ | sh && \
    systemctl enable docker && \
    yum clean all

RUN curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | bash && \
    yum -y install gitlab-runner && \
    yum clean all && \
    wget -qO /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 && \
    chmod +x /usr/bin/dumb-init

RUN cd /tmp &&\
    curl http://download.redis.io/redis-stable.tar.gz | tar xz &&\
    make -C redis-stable &&\
    cp redis-stable/src/redis-cli /usr/local/bin &&\
    rm -rf /tmp/redis-stable

ENV NGX_ROOT /usr/local/openresty/nginx
ENV PATH $PATH:$NGX_ROOT/sbin:/usr/local/bin

ADD run.sh /home
RUN chmod +x /home/run.sh && \
    chmod a+rw -R $NGX_ROOT && \
    nginx -V

WORKDIR /home/gitlab-runner
    
CMD /home/run.sh
