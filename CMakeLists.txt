cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.8)

project(com.github.artemanufrij.webpin)
include (GNUInstallDirs)
set (DATADIR "${CMAKE_INSTALL_FULL_DATAROOTDIR}")
set (PKGDATADIR "${DATADIR}/${CMAKE_PROJECT_NAME}")
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
add_definitions ("-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\"")

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED 
    gobject-2.0
    glib-2.0
    gio-2.0 
    gtk+-3.0>=3.12 
    gthread-2.0 
    granite 
    gee-0.8 
    webkit2gtk-3.0 
    libsoup-2.4 
    gdk-pixbuf-2.0
)

#
add_subdirectory(vapi)
add_subdirectory(po)

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

include(ValaPrecompile)
find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.26.0" MINIMUM)

add_subdirectory (src)
add_subdirectory (data)
add_subdirectory (schemas)
