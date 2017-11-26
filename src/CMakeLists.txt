vala_precompile(VALA_C ${CMAKE_PROJECT_NAME}
    Widgets/WebItem.vala
    Widgets/Views/WebItemsView.vala
    Widgets/Views/Editor.vala
    Widgets/Browser.vala
    Windows/WebApp.vala
    Objects/DesktopFile.vala
    Dialogs/Preferences.vala
    Services/DesktopFilesManager.vala
    Settings.vala
    MainWindow.vala
    Application.vala
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
