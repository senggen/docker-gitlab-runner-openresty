FROM centos:7

ARG RESTY_VERSION="1.15.8.1rc1"
ARG RESTY_LUAROCKS_VERSION="3.0.4"

LABEL resty_luarocks_version="${RESTY_LUAROCKS_VERSION}"

# Openresty的依赖
RUN yum install -y pcre-devel openssl-devel gcc curl gettext make unzip perl \
    && yum clean all

# Openresty
RUN cd /tmp \
    && curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && cd openresty-${RESTY_VERSION} \
    && ./configure --with-luajit \
    && make \
    && make install \
    && cd /tmp \
    && rm -rf openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
    && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log

# Luarocks
RUN cd /tmp \
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
    && rm -rf luarocks-${RESTY_LUAROCKS_VERSION} luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

# Add LuaRocks paths
# If OpenResty changes, these may need updating:
#    /usr/local/openresty/bin/resty -e 'print(package.path)'
#    /usr/local/openresty/bin/resty -e 'print(package.cpath)'
ENV LUA_PATH="/usr/local/openresty/site/lualib/?.ljbc;/usr/local/openresty/site/lualib/?/init.ljbc;/usr/local/openresty/lualib/?.ljbc;/usr/local/openresty/lualib/?/init.ljbc;/usr/local/openresty/site/lualib/?.lua;/usr/local/openresty/site/lualib/?/init.lua;/usr/local/openresty/lualib/?.lua;/usr/local/openresty/lualib/?/init.lua;./?.lua;/usr/local/openresty/luajit/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?/init.lua"

ENV LUA_CPATH="/usr/local/openresty/site/lualib/?.so;/usr/local/openresty/lualib/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so"

# Luacheck & Luacov
RUN luarocks install luacheck && luarocks install luacov

# Docker
RUN curl -fsSL get.docker.com -o get-docker.sh && \
    sh get-docker.sh --mirror Aliyun && \
    systemctl enable docker && \
    rm get-docker.sh && \
    yum clean all

# Gitlab Runner
RUN curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | bash && \
    yum -y install wget gitlab-runner && \
    yum clean all && \
    wget -qO /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 && \
    chmod +x /usr/bin/dumb-init

ENV NGX_ROOT /usr/local/openresty/nginx
ENV PATH $PATH:$NGX_ROOT/sbin:/usr/local/bin

ADD run.sh /home
RUN chmod +x /home/run.sh && \
    chmod a+rw -R $NGX_ROOT

WORKDIR /home/gitlab-runner

CMD /home/run.sh
