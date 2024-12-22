include(FetchContent)

message(STATUS "Fetching wxWidgets...")

set(wxBUILD_SHARED OFF CACHE BOOL "")

FetchContent_Declare(
	wxWidgets
	URL https://github.com/wxWidgets/wxWidgets/releases/download/v3.2.2/wxWidgets-3.2.2.zip
    DOWNLOAD_EXTRACT_TIMESTAMP ON
)
FetchContent_MakeAvailable(wxWidgets)