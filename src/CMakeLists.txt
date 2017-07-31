vala_precompile(VALA_C ${CMAKE_PROJECT_NAME}
    Widgets/ApplicationIcon.vala
    Widgets/ApplicationsView.vala
    AppWindow.vala
    Assistant.vala
    DesktopFile.vala
    InfoDialog.vala
    Settings.vala
    UrlEntry.vala
    WebApp.vala
    WebBar.vala
    Webby.vala
    WebAppWindow.vala
PACKAGES
    gtk+-3.0
    granite
    gio-2.0
    gee-0.8
    posix
    webkit2gtk-4.0
    libsoup-2.4
    gdk-pixbuf-2.0

OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --thread
    --target-glib=2.32
)

add_executable (${CMAKE_PROJECT_NAME} ${VALA_C})
target_link_libraries (${CMAKE_PROJECT_NAME} ${DEPS_LIBRARIES})

# Installation
install (TARGETS ${CMAKE_PROJECT_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})
