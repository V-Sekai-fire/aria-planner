# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#
# Makefile for building Chuffed solver NIF

# Detect OS
UNAME_S := $(shell uname -s 2>nul || echo Windows_NT)
ifeq ($(OS),Windows_NT)
    IS_WINDOWS := 1
else
    IS_WINDOWS := 0
endif

# Erlang/Elixir paths
ERLANG_ERTS_DIR := $(shell erl -eval 'io:format("~s", [code:root_dir()])' -noshell -s init stop)/erts-$(shell erl -eval 'io:format("~s", [erlang:system_info(version)])' -noshell -s init stop)
ERLANG_INCLUDE_DIR := $(ERLANG_ERTS_DIR)/include
ERLANG_LIB_DIR := $(ERLANG_ERTS_DIR)/lib

# Compiler detection and settings
ifeq ($(IS_WINDOWS),1)
    # Windows: Try to detect compiler
    ifeq ($(shell where cl.exe 2>nul),)
        # No MSVC, try MinGW g++
        ifeq ($(shell where g++.exe 2>nul),)
            CXX := g++
        else
            CXX := g++.exe
        endif
        CXXFLAGS := -std=c++17 -fPIC -O2 -Wall -Wextra -D_WIN32
        LDFLAGS := -shared -fPIC
    else
        # Use MSVC
        CXX := cl.exe
        CXXFLAGS := /std:c++17 /O2 /W3 /D_WIN32 /EHsc /LD
        LDFLAGS := /LD
        INCLUDES := /I$(ERLANG_INCLUDE_DIR)
    endif
else
    # Unix/Linux/Mac
    CXX := g++
    CXXFLAGS := -std=c++17 -fPIC -O2 -Wall -Wextra
    INCLUDES := -I$(ERLANG_INCLUDE_DIR)
endif

# Set includes if not using MSVC
ifneq ($(CXX),cl.exe)
    INCLUDES := -I$(ERLANG_INCLUDE_DIR)
endif

# Chuffed paths - adjust these to match your Chuffed installation
# For now, we use Chuffed via command-line (chuffed executable)
# To use Chuffed's C++ API directly, uncomment and adjust these:
# CHUFFED_INCLUDE := -I/usr/local/include/chuffed -I/opt/chuffed/include
# CHUFFED_LIB := -L/usr/local/lib -L/opt/chuffed/lib
# CHUFFED_LIBS := -lchuffed
CHUFFED_INCLUDE :=
CHUFFED_LIB :=
CHUFFED_LIBS :=

# Platform-specific settings
ifeq ($(IS_WINDOWS),1)
    SO_EXT := .dll
    MKDIR := if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)
    RM := del /Q
    RMDIR := rmdir /S /Q
else
    ifeq ($(UNAME_S),Linux)
        LDFLAGS := -shared -fPIC
        SO_EXT := .so
    endif
    ifeq ($(UNAME_S),Darwin)
        LDFLAGS := -dynamiclib -undefined dynamic_lookup
        SO_EXT := .so
    endif
    MKDIR := mkdir -p
    RM := rm -f
    RMDIR := rm -rf
endif

# Source and output
SRC_DIR := c_src
BUILD_DIR := priv
TARGET := $(BUILD_DIR)/chuffed_solver_nif$(SO_EXT)

# Source files
SOURCES := $(SRC_DIR)/chuffed_solver.cpp
OBJECTS := $(SOURCES:.cpp=.o)

# Default target
all: $(TARGET)

# Build the shared library
ifeq ($(CXX),cl.exe)
# MSVC build
$(TARGET): $(SOURCES) | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDES) $(CHUFFED_INCLUDE) $(SOURCES) $(LDFLAGS) /Fe:$@ $(CHUFFED_LIB) $(CHUFFED_LIBS)
	@echo Built: $@
else
# GCC/Clang build
$(TARGET): $(OBJECTS) | $(BUILD_DIR)
	$(CXX) $(LDFLAGS) -o $@ $(OBJECTS) $(CHUFFED_LIB) $(CHUFFED_LIBS)
	@echo "Built: $@"

# Compile source files
$(SRC_DIR)/%.o: $(SRC_DIR)/%.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) $(CHUFFED_INCLUDE) -c $< -o $@
endif

# Create build directory
$(BUILD_DIR):
ifeq ($(IS_WINDOWS),1)
	@if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)
else
	@mkdir -p $(BUILD_DIR)
endif

# Clean build artifacts
clean:
ifeq ($(IS_WINDOWS),1)
	@if exist $(BUILD_DIR) $(RMDIR) $(BUILD_DIR)
	@if exist $(SRC_DIR)\*.o $(RM) $(SRC_DIR)\*.o
else
	@$(RMDIR) $(BUILD_DIR)
	@$(RM) $(SRC_DIR)/*.o
endif

# Install dependencies (placeholder - adjust for your system)
install-deps:
	@echo "Please install Chuffed:"
	@echo "  - Download from https://github.com/chuffed/chuffed"
	@echo "  - Build and install Chuffed"
	@echo "  - Update CHUFFED_INCLUDE and CHUFFED_LIB paths in this Makefile"

.PHONY: all clean install-deps

