# You can find the new timestamped tags here: https://hub.docker.com/r/gitpod/workspace-base/tags
FROM gitpod/workspace-base:2022-05-08-14-31-53

# Install R and ccache
RUN sudo apt update
RUN sudo apt install -y r-base
RUN sudo apt install -y ccache
RUN sudo apt install -y libharfbuzz-dev libfribidi-dev

# Install pak in R 
RUN sudo R -q -e 'install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))'
#Install R dependencies
RUN sudo R -q -e 'pak::pak("rlang"); pak::pak("devtools"); pak::pak("deps::.")'