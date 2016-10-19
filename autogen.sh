#!/usr/bin/env sh

set -e

URL="http://localhost/rootfs.tar.xz"
DOWNLOAD="curl -L -# -o rootfs.tar.xz"
MATCHES="usr/share/(doc|man|locale)/|var/(log|run|cache)/"

if [ "$(command -v wget 2>/dev/null || :)" ]; then
    DOWNLOAD="wget -q -O rootfs.tar.xz"
    if [ "$(wget --help | grep '\--show-progress')" ]; then
        DOWNLOAD="${DOWNLOAD} --show-progress"
    fi
fi

echo "Baixando..."
$DOWNLOAD $URL
echo "Descomprimindo..."
xz -d -f rootfs.tar.xz
echo "Reduzindo..."
tar -tf rootfs.tar | grep -P $MATCHES | sort -r | xargs tar -f rootfs.tar --delete
echo "Comprimindo..."
xz -z rootfs.tar
echo "Terminado!"
