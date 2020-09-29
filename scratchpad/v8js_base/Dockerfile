FROM centos:latest
MAINTAINER Logos01 < Logos01 @ irc.freenode.net >
# BASED ON stesie/v8js Dockerfile
## -- updated to use build process for v8 versions more recent than 5.5.x
## THIS MAY NOT ACTUALLY EXECUTE. (Was tested interactively, may have missed steps.)


#RUN export libv8_version="5.7.492.69"                                       && \
RUN export libv8_version="6.4.388.18"                                       && \
    export v8js_version="2.1.0"                                             && \
    yum install      -y epel-release                                        && \
    yum localinstall -y https://centos7.iuscommunity.org/ius-release.rpm    && \
    yum install -y      \
        git             \
        subversion      \
        make            \
        gcc-c++         \
        python27        \
        curl            \
        php71u-cli      \
        php71u-devel    \
        chrpath         \
        wget            \
        bzip2           \
        glib2-devel     \
        &&              \
                                                                               \
    git clone                                                            \
        https://chromium.googlesource.com/chromium/tools/depot_tools.git \
        /tmp/depot_tools                                                 \
        &&                                                               \
                                                                               \
    export PATH="$PATH:/tmp/depot_tools" \
        &&                               \
                                                                               \
    cd /usr/local/src  \
        &&             \
        fetch v8       \
        &&             \
        cd v8          \
        &&             \
                                                                               \
    git checkout ${libv8_version} \
        &&                  \
        gclient sync        \
        &&                  \
                                                                               \
    tools/dev/v8gen.py x64.release          \
            -- is_component_build=true      \
               is_debug=false               \
               v8_enable_i18n_support=false \
        &&                             \
        ninja -C out.gn/x64.release    \
        &&                             \
                                                                               \
    mkdir -p /usr/local/lib/                        \
        &&                                          \
    mkdir -p /usr/local/include                     \
        &&                                          \
    cp                                              \
        out.gn/x64.release/lib*.so                  \
        out.gn/x64.release/*_blob.bin               \ 
        /usr/local/lib/                             \
        &&                                          \
    cp -R include/* /usr/local/include/             \ 
        &&                                          \
    cd out.gn/x64.release/obj                       \
        &&                                          \
    ar rcsDT libv8_libplatform.a v8_libplatform/*.o \
        &&                                          \
    echo -e "create /usr/local/lib/libv8_libplatform.a\naddlib /usr/local/src/v8/out.gn/x64.release/obj/libv8_libplatform.a\nsave\nend" | ar -M                                    \
        &&                                          \
                                                                               \
    cd /tmp                                             \ 
        &&                                              \
    git clone https://github.com/phpv8/v8js.git         \
        &&                                              \
    cd v8js                                             \
        &&                                              \
    git checkout ${v8js_version}                        \
        &&                                              \
    phpize                                              \
        &&                                              \
    ./configure --with-v8js=/usr/local/                 \
        &&                                              \
    make -j 4                                           \
        &&                                              \
    make test                                           \
        &&                                              \
    make install                                        \
        &&                                              \
    echo "extension=v8js.so" > /etc/php.d/99-v8js.ini   \
        &&                                              \
                                                                                \
    rm -rf                  \
        /tmp/depot_tools    \
        /usr/local/src/v8   \
        /usr/local/src/v8js \
        &&                  \
                                                                                \
    yum erase -y            \
        subversion          \
        make                \
        gcc-c++             \
        php71u-devel        \
        chrpath             \
        glib2-devel         \
        &&                  \
                                                                               \
    yum autoremove -y
