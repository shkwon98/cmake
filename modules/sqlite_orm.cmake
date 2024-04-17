find_package(sqlite_orm CONFIG)

if(NOT sqlite_orm_FOUND)
    message(STATUS "Downloading sqlite_orm")
    include(FetchContent)

    set(FETCHCONTENT_QUIET OFF)
    FetchContent_Declare(sqlite_orm
        GIT_REPOSITORY https://github.com/fnc12/sqlite_orm.git
        GIT_TAG        1.6
        GIT_PROGRESS   TRUE
        GIT_SHALLOW    TRUE)
    FetchContent_MakeAvailable(sqlite_orm)
endif()