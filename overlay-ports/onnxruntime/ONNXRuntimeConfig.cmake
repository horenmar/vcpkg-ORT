find_path(ONNXRuntime_INCLUDE_DIR
  NAMES onnxruntime_cxx_api.h
  PATH_SUFFIXES onnxruntime
  REQUIRED
)

# Note: We always expect at least the release mode artifacts to be there,
#       but the debug mode artifacts do not have to be there. This happens
#       e.g. when vcpkg has `set(VCPKG_BUILD_TYPE release)` in the triplet
#       file, and thus builds only release side of the dep tree.
#       (This is used by ae-sdk to ensure that it finds release-mode
#       artifacts only.)

# Prepare a dummy "all targets" target
add_library(ONNXRuntime::ONNXRuntime INTERFACE IMPORTED)

set(ORT_LIBRARIES_TO_FIND
  onnxruntime_common
  onnxruntime_flatbuffers
  onnxruntime_framework
  onnxruntime_graph
  onnxruntime_mlas
  onnxruntime_optimizer
  onnxruntime_providers
  onnxruntime_session
  onnxruntime_util
)

function(CreateOrtTarget targetName debugPath releasePath)
  # Impl note: Strings ending with "-NOTFOUND" are considered false in CMake.
  #            This is amazingly terrible idea, but c'est la CMake
  add_library(${targetName} STATIC IMPORTED)
  set_target_properties(${targetName}
    PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES "${ONNXRuntime_INCLUDE_DIR}"
  )

  # We always require release artifact to be present, but debug is
  # optional. This reflects the `set(VCPKG_BUILD_TYPE release)` setup
  set(_ImportedConfigs "Release")
  if (debugPath)
    list(APPEND _ImportedConfigs "Debug")
    set_target_properties(${targetName}
      PROPERTIES
        IMPORTED_LOCATION_DEBUG "${debugPath}"
    )
  endif()

  set_target_properties(${targetName}
    PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES "${ONNXRuntime_INCLUDE_DIR}"
      IMPORTED_CONFIGURATIONS "${_ImportedConfigs}"
      IMPORTED_LOCATION_RELEASE "${releasePath}"
  )
  target_link_libraries(ONNXRuntime::ONNXRuntime INTERFACE ${targetName})
endfunction()


foreach(ORT_LIB ${ORT_LIBRARIES_TO_FIND})
  string(SUBSTRING "${ORT_LIB}" 12 -1 ADJUSTED_NAME)
  find_library(ONNXRuntime_${ADJUSTED_NAME}_LIBRARY_DEBUG
    NAMES "${ORT_LIB}"
    PATHS "${CMAKE_CURRENT_LIST_DIR}/../../debug/lib"
    NO_DEFAULT_PATH
  )
  find_library(ONNXRuntime_${ADJUSTED_NAME}_LIBRARY_RELEASE
    NAMES "${ORT_LIB}"
    PATHS "${CMAKE_CURRENT_LIST_DIR}/../../lib"
    NO_DEFAULT_PATH
    REQUIRED
  )

  # Prepare a target for this library
  CreateOrtTarget(ONNXRuntime::${ADJUSTED_NAME}
                  "${ONNXRuntime_${ADJUSTED_NAME}_LIBRARY_DEBUG}"
                  "${ONNXRuntime_${ADJUSTED_NAME}_LIBRARY_RELEASE}"
  )
endforeach()

# These are non-ORT libraries that we source from ORT build anyway,
# for compatibility reasons
set(OTHER_LIBS_TO_FIND
  clog
  cpuinfo
  flatbuffers
  nsync
  nsync_cpp
  onnx
  onnx_proto
)


foreach(NON_ORT_LIB ${OTHER_LIBS_TO_FIND})
  find_library(ONNXRuntimeExt_${NON_ORT_LIB}_LIBRARY_DEBUG
    NAMES "${NON_ORT_LIB}" "${NON_ORT_LIB}d" "lib${NON_ORT_LIB}" "lib${NON_ORT_LIB}d"
    PATHS "${CMAKE_CURRENT_LIST_DIR}/../../debug/lib"
    NO_DEFAULT_PATH
  )
  find_library(ONNXRuntimeExt_${NON_ORT_LIB}_LIBRARY_RELEASE
    NAMES "${NON_ORT_LIB}" "lib${NON_ORT_LIB}"
    PATHS "${CMAKE_CURRENT_LIST_DIR}/../../lib"
    NO_DEFAULT_PATH
    REQUIRED
  )

  CreateOrtTarget(ONNXRuntimeExt::${NON_ORT_LIB}
                  "${ONNXRuntimeExt_${NON_ORT_LIB}_LIBRARY_DEBUG}"
                  "${ONNXRuntimeExt_${NON_ORT_LIB}_LIBRARY_RELEASE}"
  )
endforeach()


## Note: The dependencies below are not neccessarily minimal/full, because
#        they were derived experimentally from trying to link pexlib against
#        ONNXRuntime::session.

include(CMakeFindDependencyMacro)

## For some ORT dependencies we do use vcpkg-provided packages
## We have to bring them into scope here
find_dependency(re2 CONFIG REQUIRED)
# FlatBuffers run into version and ABI issues due to ORT's custom patches
#find_dependency(flatbuffers CONFIG REQUIRED)
find_dependency(protobuf CONFIG REQUIRED)
find_dependency(absl CONFIG REQUIRED)


## Finally we set up interlibrary dependencies

## These are not ORT-native libraries
target_link_libraries(ONNXRuntimeExt::cpuinfo INTERFACE ONNXRuntimeExt::clog)
target_link_libraries(ONNXRuntimeExt::nsync_cpp INTERFACE ONNXRuntimeExt::nsync)
target_link_libraries(ONNXRuntimeExt::onnx INTERFACE ONNXRuntimeExt::onnx_proto)
target_link_libraries(ONNXRuntimeExt::onnx_proto INTERFACE protobuf::libprotobuf)

## Plaftform-specific dependencies
if (APPLE)
  find_library(FOUNDATION_FRAMEWORK Foundation REQUIRED)
  target_link_libraries(ONNXRuntime::session INTERFACE ${FOUNDATION_FRAMEWORK})
endif ()

## These are actual ORT libraries
target_link_libraries(ONNXRuntime::common
  INTERFACE
    ONNXRuntimeExt::cpuinfo
    ONNXRuntimeExt::nsync_cpp
    absl::hash
)

target_link_libraries(ONNXRuntime::flatbuffers
  INTERFACE
    ONNXRuntimeExt::flatbuffers
)

target_link_libraries(ONNXRuntime::framework
  INTERFACE
    ONNXRuntime::common
    ONNXRuntime::graph
    ONNXRuntimeExt::nsync_cpp
    absl::raw_hash_set
    absl::hash
    absl::city
)

target_link_libraries(ONNXRuntime::graph
  INTERFACE
    ONNXRuntime::common
    ONNXRuntime::flatbuffers
    ONNXRuntimeExt::nsync_cpp
    ONNXRuntimeExt::onnx
)

target_link_libraries(ONNXRuntime::optimizer
  INTERFACE
    ONNXRuntime::graph
    ONNXRuntimeExt::onnx
)

target_link_libraries(ONNXRuntime::providers
  INTERFACE
    ONNXRuntime::mlas
    ONNXRuntime::framework
    ONNXRuntimeExt::nsync_cpp
    ONNXRuntimeExt::onnx
    re2::re2
    absl::hash
    absl::raw_hash_set
    absl::throw_delegate
)

target_link_libraries(ONNXRuntime::session
  INTERFACE
    ONNXRuntime::flatbuffers
    ONNXRuntime::framework
    ONNXRuntime::optimizer
    ONNXRuntime::providers
    ONNXRuntime::util
    ONNXRuntimeExt::nsync_cpp
    ONNXRuntimeExt::onnx
)

target_link_libraries(ONNXRuntime::util
  INTERFACE
    ONNXRuntime::mlas
)

set(ONNXRuntime_FOUND TRUE)
