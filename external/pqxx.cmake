find_package(PQXX CONFIG)

if(NOT PQXX_FOUND)
    message(STATUS "Downloading libpqxx")
    include(FetchContent)

    set(SKIP_BUILD_TEST ON CACHE BOOL "Skip building tests" FORCE)
    set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ standard to use" FORCE)

    set(FETCHCONTENT_QUIET OFF)
    FetchContent_Declare(libpqxx
        GIT_REPOSITORY https://github.com/jtv/libpqxx.git
        GIT_TAG        7.9.0
        GIT_PROGRESS   TRUE
        GIT_SHALLOW    TRUE)
    FetchContent_MakeAvailable(libpqxx)
endif()
