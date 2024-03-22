# cmake needs this line
cmake_minimum_required(VERSION 2.8)

# Define project name
project(MRI_navigators)

# Find OpenCV, you may need to set OpenCV_DIR variable
# to the absolute path to the directory containing OpenCVConfig.cmake file
# via the command line or GUI
find_package(OpenCV REQUIRED)
# Find OpenMP for parallelization
find_package(OpenMP REQUIRED)

# If the package has been found, several variables will
# be set, you can find the full list with descriptions
# in the OpenCVConfig.cmake file.
# Print some message showing some of them
message(STATUS "OpenCV library status:")
message(STATUS "    version: ${OpenCV_VERSION}")
message(STATUS "    libraries: ${OpenCV_LIBS}")
message(STATUS "    include path: ${OpenCV_INCLUDE_DIRS}")

if(CMAKE_VERSION VERSION_LESS "2.8.11")
  # Add OpenCV headers location to your include paths
  include_directories(${OpenCV_INCLUDE_DIRS})
endif()

# Add source files
set(CALCSHIFT_SOURCES
    CalcShift_cppwrapper.cpp
    calculate_shift_vector.cpp
    Matrix.cpp
    SVD.cpp
)

# Declare the executable target built from your sources
add_executable(opencv_trackVideo tracking.cpp)
add_executable(test_tracking4matlab test_tracking4matlab.cpp)
add_library(tracking4matlab SHARED tracking4matlab.cpp)
add_library(CalcShift_cppwrapper SHARED ${CALCSHIFT_SOURCES})

# Set specific flags for the library target
set_target_properties(CalcShift_cppwrapper PROPERTIES
    COMPILE_FLAGS "-shared -fPIC -Dcompile_offline"
)

# Link your application with OpenCV libraries
#target_link_libraries(opencv_trackVideo LINK_PRIVATE ${OpenCV_LIBS} OpenMP::OpenMP_CXX)
target_link_libraries(opencv_trackVideo LINK_PRIVATE ${OpenCV_LIBS})
target_link_libraries(tracking4matlab LINK_PRIVATE ${OpenCV_LIBS})
target_link_libraries(test_tracking4matlab LINK_PRIVATE ${OpenCV_LIBS} tracking4matlab)

# Make install directive.
install(TARGETS opencv_trackVideo test_tracking4matlab DESTINATION bin)
install(TARGETS tracking4matlab CalcShift_cppwrapper DESTINATION lib)

