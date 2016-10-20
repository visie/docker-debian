#!/usr/bin/env sh

set -e

# Se não formos root, apenas executa o comando desejado
if [ -n "$(whoami 2>/dev/null)" -a "$(whoami 2>/dev/null)" != "root" ]; then
    HOME=$(getent passwd `whoami` | awk -F':' '{print $(NF - 1)}')
    SHELL=$(getent passwd `whoami` | awk -F':' '{print $NF}')
    COMMAND=$(test -n "${1}" && echo ${@} || echo "${SHELL} -l")
    exec env -i HOME=${HOME} ${COMMAND}
fi

# Se somos root e desejamos executar como root...
UID=$(test -z ${UID} && echo `id -u` || echo ${UID})

if [ "$(whoami 2>/dev/null)" = "root" -a "$(id -u)" = "${UID}" ]; then
    exec env -i $(test -n "${1}" && echo ${@} || echo "/bin/bash -l")
fi

# Se desejamos executar como outro usuário...

# ... primeiro garantimos que ele exista ...
if [ "$(echo ${UID} | grep -P '^\d+:\d+$')" ]; then
    GID=$(echo ${UID} | cut -f2 -d':')
    UID=$(echo ${UID} | cut -f1 -d':')
fi

GID=$(test -z ${GID} && echo ${UID} || echo ${GID})

if [ -z "$(getent passwd {$UID})" ]; then
    groupadd -f -g ${GID} -o docker
    useradd -d /home/docker -g ${GID} -M -N -o -s /bin/bash -u ${UID} docker
fi

# ... garantimos que ele tenha uma home ...
HOME=$(getent passwd ${UID} | awk -F':' '{print $(NF - 1)}')
HOME=$(test -z ${HOME} && echo /home/docker || echo ${HOME})

if [ ! -d ${HOME} ]; then
    cp -r /etc/skel ${HOME}
    chown -R ${UID}:${GID} ${HOME}
fi

# ... decidimos o comando a executar ...
SHELL=$(getent passwd ${UID} | awk -F':' '{print $NF}')
COMMAND=$(test -n "${1}" && echo "${@}" || echo "${SHELL} -l")

# ... se somos root, encerramos com um ambiente de login
if [ "$(whoami)" = "root" ]; then
    test -n "${1}" && exec env -i su --command "${COMMAND}" --login docker
    exec env -i su -l docker
fi

exec env -i HOME=${HOME} ${COMMAND}
