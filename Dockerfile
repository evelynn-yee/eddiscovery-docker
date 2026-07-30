FROM ubuntu:noble AS eddbuildstage

RUN \
    echo "**** add mono package repository ****" && \
    apt update && \
    apt -y install ca-certificates gnupg && \
    gpg --homedir /tmp --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    chmod +r /usr/share/keyrings/mono-official-archive-keyring.gpg && \
    (echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/debian stable-buster main" | tee /etc/apt/sources.list.d/mono-official-stable.list) && \
    apt update

RUN \
    echo "**** install build deps ****" && \
    apt -y install \
        mono-devel \
        nuget \
        git

ARG EDD_VERSION="Release_19.1.9" 

RUN \
    echo "**** build EDDiscovery ****" && \
    mkdir /eddiscovery && \
    git clone https://github.com/EDDiscovery/EDDiscovery.git eddiscovery && \
    cd /eddiscovery && \
    git checkout --force ${EDD_VERSION} && \
    git submodule init && \
    git submodule update && \
    nuget restore && \
    chmod +x monobuild && \
    ./monobuild

FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntunoble

COPY --from=eddbuildstage /eddiscovery/EDDiscovery/bin/Debug /EDDiscovery

RUN \
    echo "**** add mono package repository ****" && \
    apt install -y ca-certificates gnupg && \
    gpg --homedir /tmp --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    chmod +r /usr/share/keyrings/mono-official-archive-keyring.gpg && \
    (echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/debian stable-buster main" | tee /etc/apt/sources.list.d/mono-official-stable.list) && \
    apt update

RUN \
    echo "**** install run deps ****" && \
    apt -y install \
        mono-complete

COPY /branding /etc/s6-overlay/s6-rc.d/init-adduser/branding
COPY /root /
