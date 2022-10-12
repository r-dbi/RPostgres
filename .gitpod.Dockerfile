# You can find the new timestamped tags here: https://hub.docker.com/r/gitpod/workspace-base/tags
FROM gitpod/workspace-base:2022-05-08-14-31-53

# Install R 
RUN sudo apt update
RUN sudo apt install -y r-base

# Install pak in R 
RUN sudo R -q -e 'install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))'