FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      tar \
      lib32gcc-s1 \
      libstdc++6:i386 \
      libcurl4:i386 && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash dst
USER dst
WORKDIR /home/dst

RUN mkdir -p /home/dst/steamcmd && \
    curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -xz -C /home/dst/steamcmd

RUN /home/dst/steamcmd/steamcmd.sh \
    +force_install_dir /home/dst/dst_server \
    +login anonymous \
    +app_update 343050 validate \
    +quit

COPY --chown=dst:dst docker /home/dst/docker
RUN chmod +x /home/dst/docker/entrypoint.sh

ENTRYPOINT ["/home/dst/docker/entrypoint.sh"]
