# Usage: add_go_executable(target)
function(add_go_executable NAME)
    go_build_envs()

    file(GLOB GO_SOURCE RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.go")
    set(GO_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${NAME})

    add_custom_command(
        OUTPUT ${GO_OUTPUT}
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        COMMAND GO_ENVS=${GO_ENVS}
                ${CMAKE_Go_COMPILER} build -o "${CMAKE_CURRENT_BINARY_DIR}/${NAME}" ${GO_SOURCE})

    add_custom_target(${NAME} ALL DEPENDS ${GO_OUTPUT})
endfunction(add_go_executable)

# Usage: add_cgo_executable(target)
function(add_cgo_executable NAME)
    go_build_envs()

    file(GLOB GO_SOURCE RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.go")
    set(CGO_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${NAME})

    add_custom_command(
        OUTPUT ${CGO_OUTPUT}
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        # COMMENT "CGO_CFLAGS: $<TARGET_PROPERTY:${NAME},CGO_CFLAGS>"
        COMMENT "CGO_LDFLAGS: $<TARGET_PROPERTY:${NAME},CGO_LDFLAGS>"
        COMMAND ${CMAKE_COMMAND} -E remove ${CGO_OUTPUT}
        COMMAND GO_ENVS=${GO_ENVS}
                CGO_ENABLED=1
                CC=${CMAKE_C_COMPILER}
                CGO_CFLAGS=$<TARGET_PROPERTY:${NAME},CGO_CFLAGS>
                CGO_LDFLAGS=$<TARGET_PROPERTY:${NAME},CGO_LDFLAGS>
                ${CMAKE_Go_COMPILER} build -o ${CGO_OUTPUT} ${GO_SOURCE})

    add_custom_target(${NAME} ALL DEPENDS ${CGO_OUTPUT})
endfunction()

# Usage: target_go_get(target PACKAGE package1 package2 ...)
function(target_go_get NAME)
    set(multiValueArgs PACKAGE)
    cmake_parse_arguments(target_go_get "" "" "${multiValueArgs}" ${ARGN})

    add_custom_target(${NAME}_GO_GET
        COMMENT "go get ${target_go_get_PACKAGE}"
        COMMAND ${CMAKE_Go_COMPILER} get ${target_go_get_PACKAGE}
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        VERBATIM)
    add_dependencies(${NAME} ${NAME}_GO_GET)
endfunction(target_go_get)

# Usage: target_cgo_link_libraries(target IMPORT lib1 lib2 ...)
function(target_cgo_link_libraries NAME)
    set(multiValueArgs IMPORT)
    cmake_parse_arguments(target_cgo_link_libraries "" "" "${multiValueArgs}" ${ARGN})

    cgo_fetch_cflags_and_ldflags(${NAME} ${target_cgo_link_libraries_IMPORT} ${NAME}_CFLAG_LIST ${NAME}_LDFLAG_LIST)
    if(CMAKE_INSTALL_RPATH)
        list(APPEND ${NAME}_LDFLAG_LIST -Wl,-rpath,${CMAKE_INSTALL_RPATH})
    endif()

    message(STATUS "CFLAGS: ${${NAME}_CFLAG_LIST}")
    message(STATUS "LDFLAGS: ${${NAME}_LDFLAG_LIST}")

    string(REPLACE ";" " " CGO_CFLAGS "${${NAME}_CFLAG_LIST}")
    string(REPLACE ";" " " CGO_LDFLAGS "${${NAME}_LDFLAG_LIST}")

    # Set the properties on the target to be used by the custom command
    set_target_properties(${NAME} PROPERTIES
        CGO_CFLAGS "${CGO_CFLAGS}"
        CGO_LDFLAGS "${CGO_LDFLAGS}")
    
    # Create a custom target for dependencies
    add_custom_target(${NAME}_CGO_LIBRARIES)
    add_dependencies(${NAME} ${NAME}_CGO_LIBRARIES)
endfunction()


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


macro(cgo_fetch_cflags_and_ldflags NAME TARGET CFLAG_LIST LDFLAG_LIST)
    message(STATUS "Fetching CFLAGS and LDFLAGS for ${TARGET}")

    # In case the given library is not a cmake target. e.g. pthread, rt, etc.
    if(NOT TARGET ${TARGET})
        if(NOT -l${TARGET} IN_LIST ${LDFLAG_LIST})
            message(STATUS "Adding -l${TARGET} to LDFLAGS")
            list(APPEND ${LDFLAG_LIST} -l${TARGET})
        endif()

    # In case the given library is a cmake target
    else()
        add_dependencies(${NAME} ${TARGET})

        get_target_property(LIBS ${TARGET} LINK_LIBRARIES)
        # Recursively fetch the flags from the dependencies
        if(LIBS)
            cgo_fetch_cflags_and_ldflags(${NAME} ${LIBS} ${CFLAG_LIST} ${LDFLAG_LIST})
        endif()

        get_target_property(TYPE ${TARGET} TYPE)
        # In case the given library is an INTERFACE_LIBRARY. e.g. Threads::Threads, etc.
        if(TYPE STREQUAL "INTERFACE_LIBRARY")
            get_target_property(LIB ${TARGET} INTERFACE_LINK_LIBRARIES)
            if(NOT ${LIB} IN_LIST ${LDFLAG_LIST})
                list(APPEND ${LDFLAG_LIST} ${LIB})
            endif()
        
        # In case the given library is a SHARED or STATIC library.
        else()
            # "-I" flags for CGO
            get_target_property(INCLUDE_DIR ${TARGET} INTERFACE_INCLUDE_DIRECTORIES)
            foreach(I ${INCLUDE_DIR})
                if(NOT -I${I} IN_LIST ${CFLAG_LIST})
                    list(APPEND ${CFLAG_LIST} -I${I})
                endif()
            endforeach()

            # "-L" flags for CGO
            get_target_property(LIB_DIR ${TARGET} BINARY_DIR)
            if(NOT -L${LIB_DIR} IN_LIST ${LDFLAG_LIST})
                list(APPEND ${LDFLAG_LIST} -L${LIB_DIR})
            endif()

            # "-l" flags for CGO
            if(NOT -l${TARGET} IN_LIST ${LDFLAG_LIST})
                list(APPEND ${LDFLAG_LIST} -l${TARGET})
            endif()
        endif()
    endif()
endmacro()