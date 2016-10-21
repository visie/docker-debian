#!/usr/bin/env sh

set -e

WHOAMI=$(whoami 2> /dev/null || true)

if [ -n "${WHOAMI}" -a -z "${UID}${USER}${USERNAME}" ]; then
    # Queremos executar sem alterar o usuário
    SHELL="$(getent passwd ${WHOAMI} | awk -F':' '{print $NF}') -l"
    HOME=$(getent passwd ${WHOAMI} | awk -F':' '{print $(NF - 1)}')
    exec env -i HOME=${HOME} $(test -z ${1} && echo ${SHELL} || echo ${@})
fi

WHOAMI=$(test "root" = "${WHOAMI}" && echo "docker" || echo ${WHOAMI})

test ${USERNAME} || USERNAME=${USER}
test ${USERNAME} || USERNAME=${WHOAMI}
test ${USERNAME} || USERNAME=docker

if [ $(echo ${UID} | grep -v -P '^\d+(:\d+)?$') ]; then
    # UID na verdade é USERNAME
    USERNAME=${UID}
    UID=
    GID=
fi

if [ $(echo ${UID} | grep -P '^\d+:\d+$') ]; then
    # UID contém o GID
    GID=$(echo ${UID} | cut -f2 -d':')
    UID=$(echo ${UID} | cut -f1 -d':')
fi

test ${UID} || UID=$(getent passwd "${USERNAME}" | cut -f3 -d':')
test ${UID} || UID=1000
test ${GID} || GID=${UID}

if [ -z "$(grep -P "${USERNAME}:[^:]*:${UID}:${GID}" /etc/passwd)" ]; then
    # O usuário desejado não existe!
    groupadd -f -g ${GID} -o ${USERNAME}
    useradd -g ${GID} -s /bin/bash -M -N -o -u ${UID} ${USERNAME}
fi

# O usuário existe e vamos garantir que tenha o UID e GID desejados
groupmod -g ${GID} -o ${USERNAME}
usermod -g ${GID} -o -u ${UID} ${USERNAME} 2>/dev/null

# Confirmando a propriedade do diretório pessoal
HOME=$(getent passwd ${USERNAME} | awk -F':' '{print $(NF - 1)}')
if [ ${HOME} ]; then
    test -d ${HOME} || cp -r /etc/skel ${HOME}
    chown -R ${UID}:${GID} ${HOME}
fi

# Definindo o comando a ser executado
if [ "$(whoami)" = "root" ]; then
    test -z ${1} && CMD="" || CMD="--command '${@}'"
    exec env -i HOME=${HOME} su $CMD --login ${USERNAME}
fi

SHELL="$(getent passwd ${USERNAME} | awk -F':' '{print $NF}') -l"
exec env -i HOME=${HOME} $(test -z ${1} && echo ${SHELL} || echo ${@})
