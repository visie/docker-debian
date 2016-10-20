FROM scratch
MAINTAINER Evandro Franco de Oliveira Rui <evandro@visie.com.br>
ADD rootfs.tar.xz /
ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
