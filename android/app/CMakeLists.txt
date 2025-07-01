cmake_minimum_required(VERSION 3.4.1)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add source files
add_library(native-lib SHARED
            src/main/cpp/native-lib.cpp)

# Find Android log library
find_library(log-lib log)

# Link libraries
target_link_libraries(native-lib
                      ${log-lib}) 