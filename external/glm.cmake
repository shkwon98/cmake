include(FetchContent)

message(STATUS "Fetching GLM...")

set(GLM_BUILD_TESTS OFF CACHE BOOL "")
set(BUILD_SHARED_LIBS OFF CACHE BOOL "")

FetchContent_Declare(
    glm
    GIT_REPOSITORY https://github.com/g-truc/glm.git
    GIT_TAG 1.0.1
    GIT_SHALLOW 1
)
FetchContent_MakeAvailable(glm)