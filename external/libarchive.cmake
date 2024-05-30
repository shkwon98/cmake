find_package(LibArchive)

if(NOT LibArchive_FOUND)
    message(STATUS "Downloading libarchive")
    include(FetchContent)

    set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries" FORCE)
    set(ENABLE_TEST       OFF CACHE BOOL "Enable tests" FORCE)
    set(ENABLE_COVERAGE   OFF CACHE BOOL "Enable coverage" FORCE)

    set(FETCHCONTENT_QUIET OFF)
    FetchContent_Declare(libarchive
        GIT_REPOSITORY https://github.com/libarchive/libarchive.git
        GIT_TAG        v3.4.0
        GIT_PROGRESS   TRUE
        GIT_SHALLOW    TRUE)
    FetchContent_MakeAvailable(libarchive)

    if(NOT TARGET LibArchive::LibArchive)
        add_library(LibArchive::LibArchive UNKNOWN IMPORTED)
        set_target_properties(LibArchive::LibArchive PROPERTIES
            IMPORTED_LOCATION "${libarchive_BINARY_DIR}/libarchive/libarchive.a"
            INTERFACE_INCLUDE_DIRECTORIES "${libarchive_SOURCE_DIR}/libarchive")
    endif()
endif()