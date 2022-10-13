cmake_minimum_required(VERSION 3.0.0)
project(RPostgres VERSION 0.1.0)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(CTest)
enable_testing()

add_library(RPostgres RPostgres.cpp)
target_include_directories(RPostgres PUBLIC 
    "/home/gitpod/R/x86_64-pc-linux-gnu-library/3.6/Rcpp/include/"
    "/home/gitpod/R/x86_64-pc-linux-gnu-library/3.6/plogr/include/")

set(CPACK_PROJECT_NAME ${PROJECT_NAME})
set(CPACK_PROJECT_VERSION ${PROJECT_VERSION})
include(CPack)
