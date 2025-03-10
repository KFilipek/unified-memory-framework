# Copyright (C) 2025 Intel Corporation
# Under the Apache License v2.0 with LLVM Exceptions. See LICENSE.TXT.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# Sets ${ret} to version of program specified by ${name} in major.minor format
include(cmake/common.cmake)

function(setup_cmake_format CMAKE_FORMAT_REQUIRED_VERSION)
    # Find cmake-format executable
    find_program(CMAKE_FORMAT NAMES cmake-format)

    if(CMAKE_FORMAT)
        get_program_version_major_minor(${CMAKE_FORMAT} CMAKE_FORMAT_VERSION)
        message(STATUS "Found cmake-format: ${CMAKE_FORMAT} "
                       "(version: ${CMAKE_FORMAT_VERSION})")

        # Check if cmake-format (in correct version) is available
        if(NOT (CMAKE_FORMAT_VERSION VERSION_EQUAL
                ${CMAKE_FORMAT_REQUIRED_VERSION}))
            message(
                FATAL_ERROR
                    "Required cmake-format version is"
                    " ${CMAKE_FORMAT_REQUIRED_VERSION}, but found"
                    " ${CMAKE_FORMAT_VERSION}")
        endif()

        # Obtain files for cmake-format check
        set(format_cmake_glob)
        foreach(
            DIR IN
            ITEMS cmake
                  benchmark
                  examples
                  include
                  src
                  test)
            list(
                APPEND
                format_cmake_glob
                "${DIR}/CMakeLists.txt"
                "${DIR}/*.cmake"
                "${DIR}/**/CMakeLists.txt"
                "${DIR}/**/*.cmake")
        endforeach()
        file(GLOB_RECURSE format_cmake_list ${format_cmake_glob})
        list(APPEND format_cmake_list "${PROJECT_SOURCE_DIR}/CMakeLists.txt")

        message(
            STATUS
                "Adding 'cmake-format-check' and 'cmake-format-apply' targets")

        add_custom_target(
            cmake-format-check
            COMMAND ${CMAKE_FORMAT} --check ${format_cmake_list}
            COMMENT "Check CMake files formatting using cmake-format")

        add_custom_target(
            cmake-format-apply
            COMMAND ${CMAKE_FORMAT} --in-place ${format_cmake_list}
            COMMENT "Format CMake files using cmake-format")
    else()
        message(
            WARNING
                "cmake-format not found. CMake formatting targets will not be added."
        )
    endif()
endfunction()
