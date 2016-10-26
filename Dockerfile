FROM scratch
MAINTAINER Evandro Franco de Oliveira Rui <evandro@visie.com.br>
ADD rootfs.tar.xz /
COPY usr /usr
ENTRYPOINT ["/usr/local/bin/entrypoint"]
