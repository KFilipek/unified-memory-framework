/*
 *
 * Copyright (C) 2024 Intel Corporation
 *
 * Under the Apache License v2.0 with LLVM Exceptions. See LICENSE.TXT.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 */

/*
 * ctl_debug.c -- implementation of the debug CTL namespace
 */

#include "ctl_debug.h"

#include <stdlib.h>

int alloc_pattern = 0;

void *read_alloc_pattern(void *value) {
    (void)value;
    return &alloc_pattern;
}

void *write_alloc_pattern(void *value) {
    alloc_pattern = atoi(value);
    return value;
}

void debug_ctl_register() {
    ctlAddPath("debug.heap.alloc_pattern=1", OPTION_TYPE_EXEC,
               OPERATION_TYPE_RW, read_alloc_pattern, write_alloc_pattern, 0);
    ctlAddPath("debug.log.enable=0", OPTION_TYPE_INT, OPERATION_TYPE_RW, 0, 0,
               0);
    ctlAddPath("debug.log.level=0", OPTION_TYPE_INT, OPERATION_TYPE_RW, 0, 0,
               0);
}

void initialize_debug_ctl(void) { debug_ctl_register(); }

void deinitialize_debug_ctl(void) {
    // TODO: Implement
}
