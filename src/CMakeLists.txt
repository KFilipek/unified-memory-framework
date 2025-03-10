# Copyright (C) 2022-2025 Intel Corporation
# Under the Apache License v2.0 with LLVM Exceptions. See LICENSE.TXT.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

set(CTL_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/ctl/ctl.c)

if(LINUX)
    set(BA_SOURCES ${BA_SOURCES}
                   ${CMAKE_CURRENT_SOURCE_DIR}/base_alloc/base_alloc_linux.c)
elseif(WINDOWS)
    set(BA_SOURCES ${BA_SOURCES}
                   ${CMAKE_CURRENT_SOURCE_DIR}/base_alloc/base_alloc_windows.c)
elseif(MACOSX)
    set(BA_SOURCES ${BA_SOURCES}
                   ${CMAKE_CURRENT_SOURCE_DIR}/base_alloc/base_alloc_linux.c)
endif()

set(BA_SOURCES
    ${BA_SOURCES}
    PARENT_SCOPE)

set(UMF_SOURCES
    ${BA_SOURCES}
    ${CTL_SOURCES}
    libumf.c
    ipc.c
    ipc_cache.c
    memory_pool.c
    memory_provider.c
    memory_provider_get_last_failed.c
    memtarget.c
    mempolicy.c
    memspace.c
    memspaces/memspace_host_all.c
    memspaces/memspace_highest_capacity.c
    memspaces/memspace_highest_bandwidth.c
    memspaces/memspace_lowest_latency.c
    memspaces/memspace_numa.c
    provider/provider_cuda.c
    provider/provider_devdax_memory.c
    provider/provider_file_memory.c
    provider/provider_fixed_memory.c
    provider/provider_level_zero.c
    provider/provider_os_memory.c
    provider/provider_tracking.c
    critnib/critnib.c
    ravl/ravl.c
    pool/pool_disjoint.c
    pool/pool_jemalloc.c
    pool/pool_proxy.c
    pool/pool_scalable.c)

# Add compile definitions to handle unsupported functions
if(NOT UMF_BUILD_CUDA_PROVIDER)
    set(UMF_COMMON_COMPILE_DEFINITIONS ${UMF_COMMON_COMPILE_DEFINITIONS}
                                       "UMF_NO_CUDA_PROVIDER=1")
endif()

if(NOT UMF_BUILD_LEVEL_ZERO_PROVIDER)
    set(UMF_COMMON_COMPILE_DEFINITIONS ${UMF_COMMON_COMPILE_DEFINITIONS}
                                       "UMF_NO_LEVEL_ZERO_PROVIDER=1")
endif()

target_sources(
    umf PRIVATE ${UMF_SOURCES}) # Docs: Repeated calls for the same <target>
                                # append items in the order called.

target_include_directories(
    umf PUBLIC $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
               $<INSTALL_INTERFACE:include>)
target_include_directories(
    umf PUBLIC $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src>
               $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src/>)
target_compile_definitions(umf PRIVATE ${UMF_COMMON_COMPILE_DEFINITIONS})
target_compile_options(umf PRIVATE -Wall -Wextra -Werror -Wpedantic)
target_compile_features(umf PUBLIC c_std_99)
