FROM ghcr.io/cynkra/rig-ubuntu:main

RUN apt-get update && apt-get install -y gnupg lsb-release time postgresql-client

RUN mkdir -p /root/workspace

COPY DESCRIPTION /root/workspace

RUN R -q -e 'pak::pak(dependencies = c("soft", "Config/Needs/build"))'
