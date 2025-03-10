# Copyright (C) 2022-2025 Intel Corporation
# Under the Apache License v2.0 with LLVM Exceptions. See LICENSE.TXT.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

cmake_minimum_required(VERSION 3.14.0 FATAL_ERROR)

set(UMF_CMAKE_VERSION 0.1.0)

project(
    umf
    VERSION ${UMF_CMAKE_VERSION}
    LANGUAGES C)

# Add custom CMake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(common)
include(CTest)
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)
find_package(PkgConfig)

setup_cmake_build_types()

option(UMF_DEVELOPER_MODE "Enable additional developer checks" OFF)
option(UMF_FORMAT_CODE_STYLE "Enable code style formatting" OFF)
option(UMF_BUILD_SHARED "Build UMF as a shared library" ON)
option(UMF_BUILD_TESTS "Build UMF tests" ON)
option(UMF_BUILD_CUDA_PROVIDER "Build UMF with CUDA provider" OFF)
option(UMF_BUILD_LEVEL_ZERO_PROVIDER "Build UMF with Level Zero provider" OFF)
option(UMF_USE_ASAN "Use AddressSanitizer" OFF)
option(UMF_USE_UBSAN "Use UndefinedBehaviorSanitizer" OFF)
option(UMF_USE_TSAN "Use ThreadSanitizer" OFF)
option(UMF_USE_MSAN "Use MemorySanitizer" OFF)

if(UMF_BUILD_SHARED)
    set(UMF_LIBRARY_TYPE SHARED)
else()
    set(UMF_LIBRARY_TYPE STATIC)
endif()

# Enabling developer mode
if(UMF_FORMAT_CODE_STYLE)
    include(cmake_format_setup)
    include(clang_format_setup)
    include(black_format_setup)
    set(CLANG_FORMAT_REQUIRED "15.0") # python -m pip install
                                      # clang-format==15.0.7
    set(CMAKE_FORMAT_REQUIRED "0.6") # python -m pip install
                                     # cmake-format==0.6.13 python -m pip
                                     # install black==24.3.0
    setup_cmake_format(${CMAKE_FORMAT_REQUIRED})
    setup_clang_format(${CLANG_FORMAT_REQUIRED})
    setup_black_format()
endif()

# OS detection (TODO: move to a separate file)
if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    set(LINUX TRUE)
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    set(WINDOWS TRUE)
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(MACOSX TRUE)
else()
    message(FATAL_ERROR "Unknown OS type")
endif()

add_library(umf)
add_subdirectory(src)

# Add docs target for creating a documentation
find_package(Python3 3.8)
if(Python3_FOUND)
    message(STATUS "Adding 'docs' target for creating a documentation.")
    add_custom_target(
        docs
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMAND UMF_VERSION=${UMF_CMAKE_VERSION} ${Python3_EXECUTABLE}
                ${PROJECT_SOURCE_DIR}/docs/generate_docs.py
        COMMENT "Generate HTML documentation using Doxygen")
endif()

message(STATUS "CMAKE_BUILD_TYPE version: ${CMAKE_BUILD_TYPE}")
