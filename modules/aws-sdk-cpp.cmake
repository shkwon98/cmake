find_package(AWSSDK CONFIG)

if(NOT AWSSDK_FOUND)
    message(STATUS "Downloading AWS SDK")
    include(FetchContent)

    set(BUILD_ONLY "rds" CACHE STRING "Build only library" FORCE)
    set(ENABLE_TESTING OFF CACHE BOOL "Enable AWS SDK TEST" FORCE)
    set(AUTORUN_UNIT_TESTS OFF CACHE BOOL "Enable AWS SDK UNIT TEST" FORCE)
    set(MINIMIZE_SIZE ON CACHE BOOL "Minimize size" FORCE)
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries" FORCE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type" FORCE)

    set(FETCHCONTENT_QUIET OFF)
    FetchContent_Declare(aws-sdk-cpp
        GIT_REPOSITORY  https://github.com/aws/aws-sdk-cpp.git
        GIT_TAG         1.11.238
        GIT_SHALLOW     TRUE)

    FetchContent_MakeAvailable(aws-sdk-cpp)
endif()