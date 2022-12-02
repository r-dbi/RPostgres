cmake_minimum_required(VERSION 3.0.0)
project(RPostgres VERSION 0.1.0)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(CTest)
enable_testing()

add_subdirectory(src)

set(CPACK_PROJECT_NAME ${PROJECT_NAME})
set(CPACK_PROJECT_VERSION ${PROJECT_VERSION})
include(CPack)
