find_package(Eigen3 CONFIG)

if(NOT Eigen3_FOUND)
    message(STATUS "Downloading Eigen3")
    include(FetchContent)

    set(EIGEN_BUILD_DOC OFF CACHE BOOL "" FORCE)
    set(BUILD_TESTING OFF)
    set(EIGEN_BUILD_PKGCONFIG OFF)

    set(FETCHCONTENT_QUIET OFF)
    FetchContent_Declare(
        eigen
        GIT_REPOSITORY https://gitlab.com/libeigen/eigen.git
        GIT_TAG        3.4.0
        GIT_PROGRESS   TRUE
        GIT_SHALLOW    TRUE
        EXCLUDE_FROM_ALL
    )
    FetchContent_MakeAvailable(eigen)
    if(NOT TARGET Eigen3::Eigen)
        add_custom_target(eigen_dummy DEPENDS eigen)
    add_library(Eigen3::eigen ALIAS eigen)
    endif()
endif()
