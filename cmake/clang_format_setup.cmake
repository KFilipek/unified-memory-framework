# Copyright (C) 2025 Intel Corporation
# Under the Apache License v2.0 with LLVM Exceptions. See LICENSE.TXT.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

include(cmake/common.cmake)

function(setup_clang_format CLANG_FORMAT_REQUIRED_VERSION)
    find_program(CLANG_FORMAT NAMES clang-format-15 clang-format-15.0
                                    clang-format)
    get_program_version_major_minor(${CLANG_FORMAT} CLANG_FORMAT_VERSION)
    message(STATUS "Found clang-format: ${CLANG_FORMAT} "
                   "(version: ${CLANG_FORMAT_VERSION})")

    # Check if clang-format (in correct version) is available for code
    # formatting.
    if(NOT (CLANG_FORMAT_VERSION VERSION_EQUAL CLANG_FORMAT_REQUIRED))
        message(FATAL_ERROR "Required clang-format version is "
                            "${CLANG_FORMAT_REQUIRED}")
    endif()

    # Obtain files for clang-format check
    set(format_clang_glob)
    foreach(
        DIR IN
        ITEMS benchmark
              examples
              include
              src
              test)
        list(
            APPEND
            format_clang_glob
            "${DIR}/*.h"
            "${DIR}/*.hpp"
            "${DIR}/*.c"
            "${DIR}/*.cpp"
            "${DIR}/**/*.h"
            "${DIR}/**/*.hpp"
            "${DIR}/**/*.c"
            "${DIR}/**/*.cpp")
    endforeach()
    file(GLOB_RECURSE format_list ${format_clang_glob})

    message(
        STATUS "Adding 'clang-format-check' and 'clang-format-apply' targets")

    add_custom_target(
        clang-format-check
        COMMAND ${CLANG_FORMAT} --style=file --dry-run -Werror ${format_list}
        COMMENT "Check files formatting using clang-format")

    add_custom_target(
        clang-format-apply
        COMMAND ${CLANG_FORMAT} --style=file -i ${format_list}
        COMMENT "Format files using clang-format")
endfunction()
