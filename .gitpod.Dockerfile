FROM gitpod/workspace-base:2022-05-08-14-31-53

RUN install-packages r-base
RUN echo "Run from the Docker!"