find_package(LibArchive)

if(NOT LibArchive_FOUND)
    message(STATUS "Downloading libarchive")
    include(FetchContent)

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
        add_custom_target(archive_tmp DEPENDS archive)
        add_library(LibArchive::LibArchive ALIAS archive)
    endif()
endif()