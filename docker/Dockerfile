FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/dst

# Install dependencies + generate locale đúng cách
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      tar \
      gosu \
      tini \
      gettext-base \
      locales \
      lib32gcc-s1 \
      libstdc++6:i386 \
      libgcc-s1:i386 \
      libc6:i386 \
      libcurl4 \
      libcurl4:i386 \
      libcurl3-gnutls \
      libcurl3-gnutls:i386 \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

# 👉 SET ENV SAU KHI GEN LOCALE (fix warning)
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Create user
RUN useradd -m -s /bin/bash dst

WORKDIR /home/dst

# Install SteamCMD
RUN mkdir -p /home/dst/steamcmd && \
    curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    | tar -xz -C /home/dst/steamcmd

# 🔥 FIX WORKSHOP + LIBRARYFOLDERS (QUAN TRỌNG NHẤT)
RUN mkdir -p /home/dst/.steam/steam/steamapps/workshop/content/322330 \
    && mkdir -p /home/dst/.steam/steam/steamapps/downloading \
    && mkdir -p /home/dst/.steam/steam/steamapps/temp \
    && mkdir -p /home/dst/.klei \
    && echo '"libraryfolders"\n{\n "0"\n {\n  "path" "/home/dst/.steam/steam"\n  "label" ""\n  "contentid" "1"\n  "totalsize" "0"\n }\n}' \
       > /home/dst/.steam/steam/steamapps/libraryfolders.vdf \
    && chown -R dst:dst /home/dst

# Copy scripts
COPY --chown=dst:dst . /home/dst/docker
RUN chmod +x /home/dst/docker/entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/home/dst/docker/entrypoint.sh"]