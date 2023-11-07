// Copyright (C) 2023 Intel Corporation
// Under the Apache License v2.0 with LLVM Exceptions. See LICENSE.TXT.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "memoryPool.hpp"
#include "pool.hpp"
#include "provider_null.h"
#include "provider_trace.h"
#include "provider.hpp"
#include "pool_disjoint_impl.hpp"
#include "pool/pool_disjoint.h"

static usm::DisjointPool::Config poolConfig() {
    usm::DisjointPool::Config config{};
    config.SlabMinSize = 4096;
    config.MaxPoolableSize = 4096;
    config.Capacity = 4;
    config.MinBucketSize = 64;
    return config;
}

struct umf_disjoint_pool_params params {
    /* .SlabMinSize = */ 4096,
    /* .MaxPoolableSize = */ 4096,
    /* .Capacity = */ 4,
    /* .MinBucketSize = */ 64,
    /* .CurPoolSize = */ 0,
    /* .PoolTrace = */ 0,
};

static auto makePool() {
    auto [ret, provider] =
        umf::memoryProviderMakeUnique<umf_test::provider_malloc>();
    EXPECT_EQ(ret, UMF_RESULT_SUCCESS);

    umf_memory_provider_handle_t provider_handle;
    provider_handle = provider.release();

    // capture provider and destroy it after the pool is destroyed
    auto poolDestructor = [provider_handle](umf_memory_pool_handle_t pool) {
        umfPoolDestroy(pool);
        umfMemoryProviderDestroy(provider_handle);
    };

    enum umf_result_t retp;
    umf_memory_pool_handle_t pool = nullptr;
    retp = umfPoolCreate(&UMF_DISJOINT_POOL_OPS, provider_handle, &params, &pool);
    EXPECT_EQ(retp, UMF_RESULT_SUCCESS);

    return umf::pool_unique_handle_t(pool, poolDestructor);
}

using umf_test::test;

TEST_F(test, freeErrorPropagation) {
    static enum umf_result_t freeReturn = UMF_RESULT_SUCCESS;
    struct memory_provider : public umf_test::provider_base {
        enum umf_result_t alloc(size_t size, size_t, void **ptr) noexcept {
            *ptr = malloc(size);
            return UMF_RESULT_SUCCESS;
        }
        enum umf_result_t free(void *ptr,
                               [[maybe_unused]] size_t size) noexcept {
            ::free(ptr);
            return freeReturn;
        }
    };

    auto [ret, providerUnique] =
        umf::memoryProviderMakeUnique<memory_provider>();
    ASSERT_EQ(ret, UMF_RESULT_SUCCESS);

    auto config = poolConfig();
    config.MaxPoolableSize =
        0; // force all allocations to go to memory provider

    auto [retp, pool] = umf::poolMakeUnique<usm::DisjointPool>(
        {std::move(providerUnique)}, config);
    EXPECT_EQ(retp, UMF_RESULT_SUCCESS);

    static constexpr size_t size = 1024;
    void *ptr = umfPoolMalloc(pool.get(), size);

    freeReturn = UMF_RESULT_ERROR_MEMORY_PROVIDER_SPECIFIC;
    auto freeRet = umfPoolFree(pool.get(), ptr);

    EXPECT_EQ(freeRet, freeReturn);
}

INSTANTIATE_TEST_SUITE_P(disjointPoolTests, umfPoolTest,
                         ::testing::Values(makePool));

INSTANTIATE_TEST_SUITE_P(
    disjointPoolTests, umfMemTest,
    ::testing::Values(std::make_tuple(
        [] {
            return umf_test::makePoolWithOOMProvider<usm::DisjointPool>(
                static_cast<int>(poolConfig().Capacity), poolConfig());
        },
        static_cast<int>(poolConfig().Capacity) / 2)));

GTEST_ALLOW_UNINSTANTIATED_PARAMETERIZED_TEST(umfMultiPoolTest);
INSTANTIATE_TEST_SUITE_P(disjointMultiPoolTests, umfMultiPoolTest,
                         ::testing::Values(makePool));
