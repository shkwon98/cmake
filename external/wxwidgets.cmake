find_package(wxWidgets CONFIG REQUIRED COMPONENTS core base)

if(NOT wxWidgets_FOUND)
   message(STATUS "Downloading wxWidgets")
   include(FetchContent)

   set(wxWidgets_USE_STATIC 1)
   set(wxBUILD_SHARED OFF)

   set(FETCHCONTENT_QUIET OFF)
   FetchContent_Declare(
      wxWidgets
      GIT_REPOSITORY https://github.com/wxWidgets/wxWidgets.git
      GIT_TAG        v3.2.1
      GIT_PROGRESS   TRUE
      GIT_SHALLOW    TRUE)
   
   FetchContent_MakeAvailable(wxwidgets)
endif()
