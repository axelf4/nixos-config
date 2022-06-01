cmake_minimum_required(VERSION 3.19)
project(spotify-inhibit-sleepd C)

find_package(PkgConfig REQUIRED)
pkg_check_modules(deps REQUIRED IMPORTED_TARGET glib-2.0 gio-2.0)

add_executable(spotify-inhibit-sleepd main.c)
target_link_libraries(spotify-inhibit-sleepd PkgConfig::deps)

install(TARGETS spotify-inhibit-sleepd)
