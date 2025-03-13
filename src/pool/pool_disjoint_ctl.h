/*
 * Copyright (C) 2025 Intel Corporation
 *
 * Under the Apache License v2.0 with LLVM Exceptions. See LICENSE.TXT.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

#ifndef UMF_POOL_DISJOINT_CTL_H
#define UMF_POOL_DISJOINT_CTL_H 1

#include "utils_concurrency.h"
#include <ctl/ctl.h>
#include <stdio.h>
#include <umf/memory_pool.h>

// Default shared limits for disjoint pool
// TODO list:
// [ ] Create tree
// [ ] Write handler
// [ ] Add to array
// [ ] Initialize
// [ ] Finalize
// [ ] Write tests

struct ctl *pool_disjoint_ctl_root;

static UTIL_ONCE_FLAG ctl_initialized = UTIL_ONCE_FLAG_INIT;

static int CTL_READ_HANDLER(capacity)(void *ctx, umf_ctl_query_source_t source,
                                      void *arg,
                                      umf_ctl_index_utlist_t *indexes,
                                      const char *extra_name,
                                      umf_ctl_query_type_t query_type) {
    /* suppress unused-parameter errors */
    (void)source, (void)indexes, (void)ctx, (void)extra_name, (void)query_type;
    printf("capacity\n");
    int *arg_out = arg;
    (void)arg_out;
    return 0;
}

static const umf_ctl_node_t CTL_NODE(default)[] = {CTL_LEAF_RO(capacity),
                                                   CTL_NODE_END};

static void initialize_pool_ctl(void) {
    pool_disjoint_ctl_root = ctl_new();
    CTL_REGISTER_MODULE(pool_disjoint_ctl_root, default);
}

static umf_result_t disjoint_pool_ctl(void *hPool, int operationType,
                                      const char *name, void *arg,
                                      umf_ctl_query_type_t query_type) {
    (void)operationType; // unused
    umf_memory_pool_handle_t pool_provider = (umf_memory_pool_handle_t)hPool;
    utils_init_once(&ctl_initialized, initialize_pool_ctl);
    return ctl_query(pool_disjoint_ctl_root, pool_provider,
                     CTL_QUERY_PROGRAMMATIC, name, query_type, arg);
}

#endif // UMF_POOL_DISJOINT_CTL_H
