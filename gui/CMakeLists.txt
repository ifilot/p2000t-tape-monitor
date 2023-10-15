cmake_minimum_required(VERSION 3.16)

# Set the project name
project(p2000t-fat-flasher LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# get Git HASH
execute_process(
    COMMAND git log -1 --format=%h
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    OUTPUT_VARIABLE GIT_HASH
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
add_compile_definitions(GIT_HASH="${GIT_HASH}")

# Find Qt6 packages
find_package(Qt5 REQUIRED COMPONENTS Widgets SerialPort)

add_executable(p2000t-fat-flasher
    src/blockmap.cpp
    src/dialogslotselection.cpp
    src/fatflashergui.cpp \
    src/fileallocationtable.cpp
    src/flashthread.cpp
    src/ioworker.cpp
    src/logwindow.cpp
    src/main.cpp
    src/mainwindow.cpp
    src/qhexview.cpp
    src/readthread.cpp
    src/serial_interface.cpp
    src/syncthread.cpp
    src/threadrun.cpp
    resources.qrc
)

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(MACOSX TRUE)
    set_target_properties(p2000t-fat-flasher PROPERTIES
        MACOSX_BUNDLE TRUE
    )
endif()

target_link_libraries(p2000t-fat-flasher PRIVATE Qt5::Core Qt5::Widgets Qt5::SerialPort)

set_target_properties(p2000t-fat-flasher PROPERTIES
    WIN32_EXECUTABLE ON
    MACOSX_BUNDLE ON
)
