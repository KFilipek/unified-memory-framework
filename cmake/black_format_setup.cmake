# Copyright (C) 2025 Intel Corporation
# Under the Apache License v2.0 with LLVM Exceptions. See LICENSE.TXT.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

include(cmake/common.cmake)

function(setup_black_format)
    find_program(BLACK NAMES black)
    # black should maintain backward compatibility, we don't have to require a
    # specific version
    if(BLACK)
        get_program_version_major_minor(${BLACK} BLACK_VERSION)
        message(STATUS "Found black: ${BLACK} (version: ${BLACK_VERSION})")

        message(
            STATUS
                "Adding 'black-format-check' and 'black-format-apply' targets")

        add_custom_target(
            black-format-check
            COMMAND ${BLACK} --check --verbose ${CMAKE_SOURCE_DIR}
            COMMENT "Check Python files formatting using black formatter")

        add_custom_target(
            black-format-apply
            COMMAND ${BLACK} ${CMAKE_SOURCE_DIR}
            COMMENT "Format Python files using black formatter")
    endif()
endfunction()
