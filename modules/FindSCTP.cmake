# - Try to find sctp
#
# Once done this will define
#  SCTP_FOUND        - System has sctp
#  SCTP_INCLUDE_DIRS - The sctp include directories
#  SCTP_LIBRARIES    - The sctp library

find_package(PkgConfig REQUIRED)
pkg_check_modules(PC_SCTP sctp)

#find Mbedtls
find_path(SCTP_INCLUDE_DIRS
    NAMES netinet/sctp.h
    HINTS ${PC_SCTP_INCLUDEDIR}
          ${CMAKE_INSTALL_PREFIX}/include
    PATHS /usr/include
          /usr/include/sctp
          /usr/include/netinet
          /usr/local/include
          /usr/local/include/sctp
          /usr/local/include/netinet
)

find_library(SCTP_LIBRARIES
    NAMES sctp
    HINTS ${PC_SCTP_LIBDIR}
          ${CMAKE_INSTALL_PREFIX}/lib
          ${CMAKE_INSTALL_PREFIX}/lib64
    PATHS /usr/lib
          /usr/lib64
          /usr/local/lib
          /usr/local/lib64
)

message(STATUS "SCTP LIBRARIES: " ${SCTP_LIBRARIES})
message(STATUS "SCTP INCLUDE DIRS: " ${SCTP_INCLUDE_DIRS})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SCTP DEFAULT_MSG SCTP_LIBRARIES SCTP_INCLUDE_DIRS)
mark_as_advanced(SCTP_LIBRARIES SCTP_INCLUDE_DIRS)