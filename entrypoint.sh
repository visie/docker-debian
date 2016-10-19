#!/usr/bin/env sh

set -e

UID=$(test -z ${UID} && id -u || echo ${UID})

if [ "${UID}" -ne "$(id -u)" ]; then
    groupadd -f -g ${UID} -o docker
    useradd -g ${UID} -o -s /bin/bash -u ${UID} docker
    cp -r /etc/skel /home/docker
    chown -R docker:docker /home/docker
    exec env -i su -l docker
fi

exec env -i /bin/bash -l
