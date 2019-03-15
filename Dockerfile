# Dockerfile - CentOS 7 - RPM version
# https://github.com/openresty/docker-openresty

ARG RESTY_IMAGE_BASE="centos"
ARG RESTY_IMAGE_TAG="7"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

LABEL maintainer="Evan Wies <evan@neomantra.net>"

ARG RESTY_IMAGE_BASE="centos"
ARG RESTY_LUAROCKS_VERSION="3.0.4"
ARG RESTY_RPM_FLAVOR=""
ARG RESTY_RPM_VERSION="1.15.8.1rc1-0.el7.centos"
ARG RESTY_RPM_ARCH="x86_64"

LABEL resty_luarocks_version="${RESTY_LUAROCKS_VERSION}"
LABEL resty_rpm_flavor="${RESTY_RPM_FLAVOR}"
LABEL resty_rpm_version="${RESTY_RPM_VERSION}"
LABEL resty_rpm_arch="${RESTY_RPM_ARCH}"

RUN yum-config-manager --add-repo https://openresty.org/package/${RESTY_IMAGE_BASE}/openresty.repo \
    && yum install -y \
        gettext \
        make \
        openresty${RESTY_RPM_FLAVOR}-${RESTY_RPM_VERSION}.${RESTY_RPM_ARCH} \
        openresty-opm-${RESTY_RPM_VERSION} \
        openresty-resty-${RESTY_RPM_VERSION} \
        unzip \
    && cd /tmp \
    && curl -fSL https://github.com/luarocks/luarocks/archive/${RESTY_LUAROCKS_VERSION}.tar.gz -o luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && tar xzf luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && cd luarocks-${RESTY_LUAROCKS_VERSION} \
    && ./configure \
        --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit \
        --lua-suffix=jit-2.1.0-beta3 \
        --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
    && make build \
    && make install \
    && cd /tmp \
    && rm -rf luarocks-${RESTY_LUAROCKS_VERSION} luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && yum remove -y make \
    && yum clean all \
    && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log

# Unused, present for parity with other Dockerfiles
# This makes some tooling/testing easier, as specifying a build-arg
# and not consuming it fails the build.
ARG RESTY_J="1"

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

# Add LuaRocks paths
# If OpenResty changes, these may need updating:
#    /usr/local/openresty/bin/resty -e 'print(package.path)'
#    /usr/local/openresty/bin/resty -e 'print(package.cpath)'
ENV LUA_PATH="/usr/local/openresty/site/lualib/?.ljbc;/usr/local/openresty/site/lualib/?/init.ljbc;/usr/local/openresty/lualib/?.ljbc;/usr/local/openresty/lualib/?/init.ljbc;/usr/local/openresty/site/lualib/?.lua;/usr/local/openresty/site/lualib/?/init.lua;/usr/local/openresty/lualib/?.lua;/usr/local/openresty/lualib/?/init.lua;./?.lua;/usr/local/openresty/luajit/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?/init.lua"

ENV LUA_CPATH="/usr/local/openresty/site/lualib/?.so;/usr/local/openresty/lualib/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so"

# Copy nginx configuration files
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY nginx.vh.default.conf /etc/nginx/conf.d/default.conf

# mine
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
