# Usage: add_go_executable(target)
function(add_go_executable NAME)
  go_build_envs()

  file(
    GLOB GO_SOURCE
    RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
    "*.go")
  set(GO_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${NAME})
  add_custom_command(
    OUTPUT ${GO_OUTPUT}
    COMMAND env ${GO_ENVS} ${CMAKE_Go_COMPILER} build -o "${CMAKE_CURRENT_BINARY_DIR}/${NAME}"
            ${CMAKE_GO_FLAGS} ${GO_SOURCE}
    COMMENT "go build ${NAME}"
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR})

  add_custom_target(${NAME} ALL DEPENDS ${GO_OUTPUT})
endfunction(add_go_executable)

# Usage: add_cgo_executable(target)
function(add_cgo_executable NAME)
  set(multiValueArgs IMPORT)
  cmake_parse_arguments(add_cgo_executable "" "" "${multiValueArgs}" ${ARGN})

  cgo_fetch_cflags_and_ldflags(add_cgo_executable_IMPORT)
  cgo_build_envs()

  file(
    GLOB GO_SOURCE
    RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
    "*.go")
  set(CGO_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${NAME})
  add_custom_command(
    OUTPUT ${CGO_OUTPUT}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Building CGO modules for ${NAME}"
    COMMAND ${CMAKE_COMMAND} -E remove ${CGO_OUTPUT}
    COMMAND env ${CGO_ENVS} ${CMAKE_Go_COMPILER} build -o ${CMAKE_CURRENT_BINARY_DIR}/${NAME}
            ${CMAKE_GO_FLAGS} ${GO_SOURCE}
    DEPENDS ${CGO_DEPS_HANDLED})

  add_custom_target(${NAME} ALL DEPENDS ${CGO_OUTPUT})
endfunction()

# Usage: target_go_get(target PACKAGE import1 import2 ...)
function(target_go_get NAME)
  set(multiValueArgs PACKAGE)
  cmake_parse_arguments(target_go_get "" "" "${multiValueArgs}" ${ARGN})

  add_custom_target(
    ${NAME}_GO_GET
    COMMAND ${CMAKE_Go_COMPILER} get ${target_go_get_PACKAGE}
    COMMENT "go get ${target_go_get_PACKAGE}"
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    VERBATIM)
  add_dependencies(${NAME} ${NAME}_GO_GET)
endfunction(target_go_get)

set(CGO_RESOLVE_BLACKLIST pthread rt gcov systemd)

set(CGO_CFLAGS_BLACKLIST
    "-Werror"
    "-Wall"
    "-Wextra"
    "-Wold-style-definition"
    "-fdiagnostics-color=always"
    "-Wformat-nonliteral"
    "-Wformat=2")

macro(go_build_envs)
  # Assume ARM7 if on ARM
  if("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "arm")
    list(APPEND GO_ENVS GOARCH=arm GOARM=7)
  endif()

  # cross compile
  if(CMAKE_CROSSCOMPILING)
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
      list(APPEND GO_ENVS GOOS=linux)
    endif()
    if(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
      list(APPEND GO_ENVS GOARCH=arm64)
    endif()
  endif()
endmacro()

macro(cgo_build_envs)
  set(CGO_ENVS CGO_ENABLED=1 CC=${CMAKE_C_COMPILER} CGO_CFLAGS="${CGO_CFLAGS}"
               CGO_LDFLAGS="${CGO_LDFLAGS}")

  # Assume ARM7 if on ARM
  if("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "arm")
    list(APPEND CGO_ENVS GOARCH=arm GOARM=7)
  endif()

  # cross compile
  if(CMAKE_CROSSCOMPILING)
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
      list(APPEND CGO_ENVS GOOS=linux)
    endif()
    if(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
      list(APPEND CGO_ENVS GOARCH=arm64)
    endif()
  endif()
endmacro()

macro(cgo_fetch_cflags_and_ldflags CGO_DEPS)
  set(CGO_LDFLAGS "")
  set(CGO_CFLAGS "")

  set(CGO_DEPS_STACK ${${CGO_DEPS}})
  set(CGO_DEPS_HANDLED "")
  set(CGO_RPATHS "")

    foreach(L ${CGO_DEPS_STACK})
      # Skip if already handled once
      if("${L}" IN_LIST CGO_DEPS_HANDLED)
        continue()
      endif()

      # Don't resolve system libs
      if("${L}" IN_LIST CGO_RESOLVE_BLACKLIST)
        continue()
      endif()

      # Resolve PkgConfig libs
      if("${L}" MATCHES "PkgConfig")
        get_target_property(L_INTERFACE_LIB ${L} INTERFACE_LINK_LIBRARIES)

        # Mark handled
        list(APPEND CGO_DEPS_HANDLED ${L})

        # Finally override L
        set(L "${L_INTERFACE_LIB}")

        # L might be a list so iterate over it when adding rpaths
        foreach(L_ITEM ${L})
          # Fetch directory and add it to rpath-link if not already added
          get_filename_component(R "${L_ITEM}" DIRECTORY)

          if(NOT "${R}" IN_LIST CGO_RPATHS)
            # Linker may need to find private libraries in the same directory
            list(APPEND CGO_RPATHS "${R}")
          endif()
        endforeach()

        # Add libraries to linker flags
        list(APPEND CGO_LDFLAGS ${L})
      else()
        # Try resolve alias
        get_target_property(L_ALIASED ${L} ALIASED_TARGET)
        if(NOT "${L_ALIASED}" MATCHES "NOTFOUND")
          set(L "${L_ALIASED}")
        endif()

        # Mark handled
        list(APPEND CGO_DEPS_HANDLED ${L})

        get_target_property(L_INCLUDES ${L} INCLUDE_DIRECTORIES)
        get_target_property(L_BUILD_DIR ${L} BINARY_DIR)

        list(APPEND CGO_LDFLAGS -L${L_BUILD_DIR})
        list(APPEND CGO_LDFLAGS -l${L})

        foreach(I ${L_INCLUDES})
          list(APPEND CGO_CFLAGS -I${I})
        endforeach()

        list(REMOVE_ITEM CGO_DEPS_STACK "${L}")

        get_target_property(DEPS ${L} LINK_LIBRARIES)
        foreach(D ${DEPS})
          list(APPEND CGO_DEPS_STACK "${D}")
        endforeach()

      endif()

    endforeach()

  # Adding cflags and ldflags ##### Must split sentences into CMake List before
  # adding cflags and ldflags
  if(CMAKE_C_FLAGS)
    string(REPLACE " " ";" CMAKE_C_FLAGS_LIST ${CMAKE_C_FLAGS})
    list(APPEND CGO_CFLAGS ${CMAKE_C_FLAGS_LIST})
  else()
    list(APPEND CGO_CFLAGS "")
  endif()

  if(CMAKE_EXE_LINKER_FLAGS)
    string(REPLACE " " ";" CMAKE_EXE_LINKER_FLAGS_LIST
                   "${CMAKE_EXE_LINKER_FLAGS}")
    list(APPEND CGO_LDFLAGS "${CMAKE_EXE_LINKER_FLAGS_LIST}")
  else()
    list(APPEND CGO_LDFLAGS "")
  endif()

  if(CMAKE_C_LINK_FLAGS)
    string(REPLACE " " ";" CMAKE_C_LINK_FLAGS_LIST "${CMAKE_C_LINK_FLAGS}")
    list(APPEND CGO_LDFLAGS "${CMAKE_C_LINK_FLAGS_LIST}")
  else()
    list(APPEND CGO_LDFLAGS "")
  endif()

  if(CMAKE_BUILD_TYPE MATCHES debug)
    string(REPLACE " " ";" CMAKE_C_FLAGS_DEBUG_LIST "${CMAKE_C_FLAGS_DEBUG}")
    list(APPEND CGO_CFLAGS ${CMAKE_C_FLAGS_DEBUG_LIST})
    string(REPLACE " " ";" CMAKE_EXE_LINKER_FLAGS_DEBUG_LIST
                   "${CMAKE_EXE_LINKER_FLAGS_DEBUG}")
    list(APPEND CGO_LDFLAGS "${CMAKE_EXE_LINKER_FLAGS_DEBUG_LIST}")
  endif()

  if(CMAKE_BUILD_TYPE MATCHES release)
    string(REPLACE " " ";" CMAKE_C_FLAGS_RELEASE_LIST
                   "${CMAKE_C_FLAGS_RELEASE}")
    list(APPEND CGO_CFLAGS ${CMAKE_C_FLAGS_RELEASE_LIST})
    string(REPLACE " " ";" CMAKE_EXE_LINKER_FLAGS_RELEASE_LIST
                   "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
    list(APPEND CGO_LDFLAGS "${CMAKE_EXE_LINKER_FLAGS_RELEASE_LIST}")
  endif()

  # Need to remove warnings for CGo to work
  foreach(F ${CGO_CFLAGS_BLACKLIST})
    list(REMOVE_ITEM CGO_CFLAGS "${F}")
  endforeach()

  # Add rpaths if present
  foreach(R ${CGO_RPATHS})
    list(APPEND CGO_LDFLAGS "-Wl,-rpath-link=${R}")
  endforeach()

endmacro()
