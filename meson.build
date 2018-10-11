project('com.github.artemanufrij.webpin','vala', 'c')

i18n = import('i18n')
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

subdir('src')
subdir('po')
subdir('data')
subdir('schemas')

executable(
    meson.project_name(),
    sources,
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('granite'),
        dependency('webkit2gtk-4.0')
    ],
    install: true
)

meson.add_install_script('meson/post_install.py')