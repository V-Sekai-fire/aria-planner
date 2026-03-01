# SPDX-License-Identifier: MIT
# C executor for glTF Interactivity (KHR_interactivity).
# Build: cmake -B build -S . && cmake --build build
# Run: build/interactivity_runner [path.glb]
cmake_minimum_required(VERSION 3.14)
project(interactivity_runner C CXX)

set(CMAKE_C_STANDARD 99)

# JSMN (minimal JSON parser, single-header)
include(FetchContent)
FetchContent_Declare(
  jsmn
  GIT_REPOSITORY https://github.com/zserge/jsmn.git
  GIT_TAG master
)
FetchContent_MakeAvailable(jsmn)
set(JSMN_INC ${jsmn_SOURCE_DIR})

add_executable(interactivity_runner
  main.c
  glb_read.c
  graph.c
)
target_include_directories(interactivity_runner PRIVATE ${JSMN_INC})

# Optional: run tests if fixture exists
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/fixtures/rope.glb")
  add_test(NAME run_rope COMMAND interactivity_runner "${CMAKE_CURRENT_SOURCE_DIR}/fixtures/rope.glb")
endif()
