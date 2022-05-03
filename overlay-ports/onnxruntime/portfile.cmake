vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_find_acquire_program(GIT)
vcpkg_find_acquire_program(PYTHON3)


# We need proper git checkout to get access to submodules, so we are doing
# the cloning outside of vcpkg helpers (those provide sources snapshost
# without the git parts).
set(ORT_CHECKOUT_DIR git-checkout)
# Commit we want to check out
set(ORT_GIT_SHA "366f4ebcb425b6a47c2b0decd3b39fa14eb9dbf6") # This is the commit tagged with 1.11.1 release

message(STATUS "Preparing sources")
set(SOURCE_PATH "${CURRENT_BUILDTREES_DIR}/${ORT_CHECKOUT_DIR}")


if (NOT EXISTS "${SOURCE_PATH}")

  vcpkg_execute_required_process(
    COMMAND ${GIT} clone https://github.com/Microsoft/onnxruntime.git ${ORT_CHECKOUT_DIR}
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}
    LOGNAME git-1-clone-${TARGET_TRIPLET}
  )

endif()

# Purge any local changes
vcpkg_execute_required_process(
  COMMAND ${GIT} clean -xfd
  WORKING_DIRECTORY ${SOURCE_PATH}
  LOGNAME git-2-clean-${TARGET_TRIPLET}
)

vcpkg_execute_required_process(
  COMMAND ${GIT} reset --hard
  WORKING_DIRECTORY ${SOURCE_PATH}
  LOGNAME git-3-reset-${TARGET_TRIPLET}
)


# Also purge changes in submodules
vcpkg_execute_required_process(
  COMMAND ${GIT} submodule foreach --recursive git clean -xfd
  WORKING_DIRECTORY ${SOURCE_PATH}
  LOGNAME git-4-clean-submodule-${TARGET_TRIPLET}
)

# And ensure that we are dealing with the right commit
vcpkg_execute_required_process(
  COMMAND ${GIT} fetch origin ${ORT_GIT_SHA}
  WORKING_DIRECTORY ${SOURCE_PATH}
  LOGNAME git-5-fetch-${TARGET_TRIPLET}
)

vcpkg_execute_required_process(
  COMMAND ${GIT} checkout ${ORT_GIT_SHA}
  WORKING_DIRECTORY ${SOURCE_PATH}
  LOGNAME git-6-checkout-${TARGET_TRIPLET}
)

vcpkg_execute_required_process(
  COMMAND ${GIT} submodule update --init --recursive
  WORKING_DIRECTORY ${SOURCE_PATH}
  LOGNAME git-7-update-submodule-${TARGET_TRIPLET}
)

# We have a bunch of patches on the clean checkout to workaround bad build script
vcpkg_apply_patches(
  SOURCE_PATH ${SOURCE_PATH}
  PATCHES
    "${CMAKE_CURRENT_LIST_DIR}/001-use-absl-from-vcpkg.patch"
    "${CMAKE_CURRENT_LIST_DIR}/002-remove-dbghelp-dependency-on-windows.patch"
    "${CMAKE_CURRENT_LIST_DIR}/004-prefer-config-search-for-packages.patch"
)

message(STATUS "Deleting old build dirs")
# Cleanup old build directories to avoid issues with dirty rebuilds
set(BUILD_DIR_DEBUG "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg")
set(BUILD_DIR_RELEASE "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel")
vcpkg_execute_required_process(
  COMMAND ${CMAKE_COMMAND} -E rm -rf ${BUILD_DIR_DEBUG} ${BUILD_DIR_RELEASE}
  #This doesn't actually matter, but the argument is required
  WORKING_DIRECTORY "${CURRENT_BUILDTREES_DIR}"
  LOGNAME delete-old-build-dir-${TARGET_TRIPLET}
)

vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}/cmake"
  OPTIONS
   "-Donnxruntime_BUILD_UNIT_TESTS=OFF"
   "-Donnxruntime_RUN_ONNX_TESTS=OFF"
   "-Donnxruntime_BUILD_WINML_TESTS=OFF"
   "-Donnxruntime_GENERATE_TEST_REPORTS=OFF"
   "-DPython_EXECUTABLE=${PYTHON3}"
   "-DPYTHON_EXECUTABLE=${PYTHON3}"
   "-Donnxruntime_ROCM_VERSION="
   "-Donnxruntime_USE_MIMALLOC_STL_ALLOCATOR=OFF"
   "-Donnxruntime_USE_MIMALLOC_ARENA_ALLOCATOR=OFF"
   "-Donnxruntime_ENABLE_PYTHON=OFF"
   "-Donnxruntime_BUILD_CSHARP=OFF"
   "-Donnxruntime_BUILD_JAVA=OFF"
   "-Donnxruntime_BUILD_NODEJS=OFF"
   "-Donnxruntime_BUILD_OBJC=OFF"
   "-Donnxruntime_BUILD_SHARED_LIB=OFF"
   "-Donnxruntime_BUILD_APPLE_FRAMEWORK=OFF"
   "-Donnxruntime_USE_DNNL=OFF"
   "-Donnxruntime_DNNL_GPU_RUNTIME="
   "-Donnxruntime_DNNL_OPENCL_ROOT="
   "-Donnxruntime_USE_NNAPI_BUILTIN=OFF"
   "-Donnxruntime_USE_RKNPU=OFF"
   "-Donnxruntime_USE_OPENMP=OFF"
   "-Donnxruntime_USE_TVM=OFF"
   "-Donnxruntime_USE_LLVM=OFF"
   "-Donnxruntime_ENABLE_MICROSOFT_INTERNAL=OFF"
   "-Donnxruntime_USE_VITISAI=OFF"
   "-Donnxruntime_USE_NUPHAR=OFF"
   "-Donnxruntime_USE_TENSORRT=OFF"
   "-Donnxruntime_TENSORRT_HOME="
   "-Donnxruntime_USE_MIGRAPHX=OFF"
   "-Donnxruntime_MIGRAPHX_HOME="
   "-Donnxruntime_CROSS_COMPILING=OFF"
   "-Donnxruntime_DISABLE_CONTRIB_OPS=OFF"
   "-Donnxruntime_DISABLE_ML_OPS=ON"
   "-Donnxruntime_DISABLE_RTTI=ON"
   "-Donnxruntime_DISABLE_EXCEPTIONS=OFF"
   "-Donnxruntime_MINIMAL_BUILD=OFF"
   "-Donnxruntime_EXTENDED_MINIMAL_BUILD=OFF"
   "-Donnxruntime_MINIMAL_BUILD_CUSTOM_OPS=OFF"
   "-Donnxruntime_REDUCED_OPS_BUILD=OFF"
   "-Donnxruntime_ENABLE_LANGUAGE_INTEROP_OPS=OFF"
   "-Donnxruntime_USE_DML=OFF"
   "-Donnxruntime_USE_WINML=OFF"
   "-Donnxruntime_BUILD_MS_EXPERIMENTAL_OPS=OFF"
   "-Donnxruntime_USE_TELEMETRY=OFF"
   "-Donnxruntime_ENABLE_LTO=OFF"
   "-Donnxruntime_ENABLE_TRANSFORMERS_TOOL_TEST=OFF"
   "-Donnxruntime_USE_ACL=OFF"
   "-Donnxruntime_USE_ACL_1902=OFF"
   "-Donnxruntime_USE_ACL_1905=OFF"
   "-Donnxruntime_USE_ACL_1908=OFF"
   "-Donnxruntime_USE_ACL_2002=OFF"
   "-Donnxruntime_USE_ARMNN=OFF"
   "-Donnxruntime_ARMNN_RELU_USE_CPU=ON"
   "-Donnxruntime_ARMNN_BN_USE_CPU=ON"
   "-Donnxruntime_ENABLE_NVTX_PROFILE=OFF"
   "-Donnxruntime_ENABLE_TRAINING=OFF"
   "-Donnxruntime_ENABLE_TRAINING_OPS=OFF"
   "-Donnxruntime_ENABLE_TRAINING_TORCH_INTEROP=OFF"
   "-Donnxruntime_ENABLE_CPU_FP16_OPS=OFF"
   "-Donnxruntime_USE_NCCL=ON"
   "-Donnxruntime_BUILD_BENCHMARKS=OFF"
   "-Donnxruntime_USE_ROCM=OFF"
   "-Donnxruntime_ROCM_HOME="
   "-DOnnxruntime_GCOV_COVERAGE=OFF"
   "-Donnxruntime_USE_MPI=ON"
   "-Donnxruntime_ENABLE_MEMORY_PROFILE=OFF"
   "-Donnxruntime_ENABLE_CUDA_LINE_NUMBER_INFO=OFF"
   "-Donnxruntime_BUILD_WEBASSEMBLY=OFF"
   "-Donnxruntime_ENABLE_WEBASSEMBLY_SIMD=OFF"
   "-Donnxruntime_ENABLE_WEBASSEMBLY_EXCEPTION_CATCHING=ON"
   "-Donnxruntime_ENABLE_WEBASSEMBLY_EXCEPTION_THROWING=OFF"
   "-Donnxruntime_ENABLE_WEBASSEMBLY_THREADS=OFF"
   "-Donnxruntime_ENABLE_WEBASSEMBLY_DEBUG_INFO=OFF"
   "-Donnxruntime_WEBASSEMBLY_MALLOC=dlmalloc"
   "-Donnxruntime_ENABLE_EAGER_MODE=OFF"
   "-Donnxruntime_ENABLE_EXTERNAL_CUSTOM_OP_SCHEMAS=OFF"
   "-Donnxruntime_BUILD_UNIT_TESTS=OFF"
   "-Donnxruntime_ENABLE_MEMLEAK_CHECKER=OFF"
   "-Donnxruntime_PREFER_SYSTEM_LIB=ON"
   "-Donnxruntime_DEV_MODE=OFF"
   "-DONNX_USE_MSVC_STATIC_RUNTIME=OFF"
   "-Dprotobuf_MSVC_STATIC_RUNTIME=OFF"
   "-Dgtest_force_shared_crt=ON"
   "-Donnxruntime_PYBIND_EXPORT_OPSCHEMA=OFF"
  MAYBE_UNUSED_VARIABLES
    "ONNX_USE_MSVC_STATIC_RUNTIME"
    Python_EXECUTABLE
    gtest_force_shared_crt
    onnxruntime_BUILD_WINML_TESTS
    onnxruntime_DNNL_GPU_RUNTIME
    onnxruntime_DNNL_OPENCL_ROOT
    onnxruntime_ENABLE_TRANSFORMERS_TOOL_TEST
    onnxruntime_ENABLE_WEBASSEMBLY_SIMD
    onnxruntime_MIGRAPHX_HOME
    onnxruntime_PYBIND_EXPORT_OPSCHEMA
    onnxruntime_ROCM_HOME
    onnxruntime_ROCM_VERSION
    onnxruntime_TENSORRT_HOME
    onnxruntime_WEBASSEMBLY_MALLOC
    protobuf_MSVC_STATIC_RUNTIME
  LOGFILE_BASE "configure-project"
)

vcpkg_cmake_build()

# Copy over headers
# Note that we flatten the resulting directory structure, because that
# is what the upstream does for their own releases. Thus, this flat
# structure mirrors what would be there when installing from a release
# compiled by the upstream.
set(HEADERS_BASE_DIR "${SOURCE_PATH}/include/onnxruntime/core")
set(HEADERS
  "${HEADERS_BASE_DIR}/providers/cpu/cpu_provider_factory.h"
  "${HEADERS_BASE_DIR}/session/onnxruntime_c_api.h"
  "${HEADERS_BASE_DIR}/session/onnxruntime_cxx_api.h"
  "${HEADERS_BASE_DIR}/session/onnxruntime_cxx_inline.h"
  "${HEADERS_BASE_DIR}/session/onnxruntime_run_options_config_keys.h"
  "${HEADERS_BASE_DIR}/session/onnxruntime_session_options_config_keys.h"
  "${HEADERS_BASE_DIR}/framework/provider_options.h"
)
file(INSTALL ${HEADERS} DESTINATION "${CURRENT_PACKAGES_DIR}/include/${PORT}")

# License has to be renamed to copyright
file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

# We provide custom Config file to make it all work
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/ONNXRuntimeConfig.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")


### Now we copy over the libraries. We will assume that the build is static
### only, to simplify the code below (and it is what we want to do overall
### anyway, we can fix the portfile for dynamic link support later on).

# Select static library extension by platform
if(VCPKG_TARGET_IS_WINDOWS)
  set(LIB_EXTN ".lib")
elseif(VCPKG_TARGET_IS_LINUX)
  set(LIB_EXTN ".a")
else()
  set(LIB_EXTN ".a")
endif()

message(STATUS "Copying over libraries")

file(GLOB_RECURSE DEBUG_LIBS
  LIST_DIRECTORIES FALSE
  "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/*${LIB_EXTN}"
)
file(COPY
  ${DEBUG_LIBS}
  DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib/"
)


file(GLOB_RECURSE RELEASE_LIBS
  LIST_DIRECTORIES FALSE
  "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/*${LIB_EXTN}"
)
file(COPY
  ${RELEASE_LIBS}
  DESTINATION "${CURRENT_PACKAGES_DIR}/lib/"
)

vcpkg_copy_pdbs()
