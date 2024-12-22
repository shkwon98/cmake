include(FetchContent)

message(STATUS "Fetching GLEW...")

if (UNIX AND NOT APPLE) # For Linux
    set(GLEW_EGL ON CACHE BOOL "")
    set(OpenGL_GL_PREFERENCE GLVND CACHE STRING "")
endif()
set(BUILD_UTILS OFF CACHE BOOL "")

FetchContent_Declare(
    glew
    URL https://github.com/nigels-com/glew/releases/download/glew-2.2.0/glew-2.2.0.zip
    SOURCE_SUBDIR build/cmake
    DOWNLOAD_EXTRACT_TIMESTAMP ON
)
FetchContent_MakeAvailable(glew)

if(NOT TARGET GLEW::glew)
    add_custom_target(glew_tmp DEPENDS glew)
    add_library(GLEW::glew ALIAS glew)
    endif()
    
if(NOT TARGET GLEW::glew_s)
    add_custom_target(glew_s_tmp DEPENDS glew_s)
    add_library(GLEW::glew_s ALIAS glew_s)
endif()

include_directories(${glew_SOURCE_DIR}/include)
