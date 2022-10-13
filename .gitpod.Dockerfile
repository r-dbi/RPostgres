# You can find the new timestamped tags here: https://hub.docker.com/r/gitpod/workspace-base/tags
FROM gitpod/workspace-base:2022-05-08-14-31-53

# Install R and ccache
RUN sudo apt update
RUN sudo apt install -y \
  r-base \
  ccache \
  cmake \
  # Install dependencies for rlang packet
  libharfbuzz-dev libfribidi-dev
