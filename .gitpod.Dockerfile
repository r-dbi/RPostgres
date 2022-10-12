# You can find the new timestamped tags here: https://hub.docker.com/r/gitpod/workspace-base/tags
FROM ubuntu:latest

# Install custom tools, runtime, etc.
# base image only got `apt` as the package manager
# install-packages is a wrapper for `apt` that helps skip a few commands in the docker env.
RUN sudo install-packages shellcheck tree llvm
RUN sudo apt update
RUN sudo apt install -y r-base