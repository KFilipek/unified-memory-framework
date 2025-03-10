# Copyright (C) 2025 Intel Corporation
# Under the Apache License v2.0 with LLVM Exceptions. See LICENSE.TXT.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

function(get_program_version_major_minor name ret)
    execute_process(
        COMMAND ${name} --version
        OUTPUT_VARIABLE cmd_ret
        ERROR_QUIET)
    string(REGEX MATCH "([0-9]+)\.([0-9]+)" VERSION "${cmd_ret}")
    set(${ret}
        ${VERSION}
        PARENT_SCOPE)
endfunction()

function(setup_cmake_build_types)
    # This build type check is not possible on Windows when CMAKE_BUILD_TYPE is
    # not set, because in this case the build type is determined after a CMake
    # configuration is done (at the build time)
    if(NOT WINDOWS)
        set(KNOWN_BUILD_TYPES Release Debug RelWithDebInfo MinSizeRel)
        string(REPLACE ";" " " KNOWN_BUILD_TYPES_STR "${KNOWN_BUILD_TYPES}")

        if(NOT CMAKE_BUILD_TYPE)
            message(
                STATUS
                    "No build type selected (CMAKE_BUILD_TYPE), defaulting to Release"
            )
            set(CMAKE_BUILD_TYPE "Release")
        else()
            message(STATUS "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")
            if(NOT CMAKE_BUILD_TYPE IN_LIST KNOWN_BUILD_TYPES)
                message(
                    WARNING
                        "Unusual build type was set (${CMAKE_BUILD_TYPE}), please make sure it is a correct one. "
                        "The following ones are supported by default: ${KNOWN_BUILD_TYPES_STR}."
                )
            endif()
        endif()

        set(CMAKE_BUILD_TYPE
            "${CMAKE_BUILD_TYPE}"
            CACHE
                STRING
                "Choose the type of build, options are: ${KNOWN_BUILD_TYPES_STR} ..."
                FORCE)
        set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
                                                     ${KNOWN_BUILD_TYPES})
    endif()
endfunction()
