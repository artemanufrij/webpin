vala_precompile(VALA_C ${CMAKE_PROJECT_NAME}
    Widgets/ApplicationIcon.vala
    Widgets/ApplicationsView.vala
    Widgets/Assistant.vala
    Application.vala
    MainWindow.vala
    DesktopFile.vala
    InfoDialog.vala
    Settings.vala
    UrlEntry.vala
    WebApp.vala
    WebBar.vala
    WebAppWindow.vala
PACKAGES
    gtk+-3.0
    granite
    webkit2gtk-4.0

OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --thread
    --target-glib=2.32
)

add_executable (${CMAKE_PROJECT_NAME} ${VALA_C})
target_link_libraries (${CMAKE_PROJECT_NAME} ${DEPS_LIBRARIES})

# Installation
install (TARGETS ${CMAKE_PROJECT_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})
