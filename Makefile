# Makefile

BUILD_DIR := build
BIN_DIR := bin
SRC_DIR := src
INC_DIR := include

# ----- Compiler settings -----
# c and c++
CC := clang
CXX := clang++
CFLAGS := -O2 -Wall
CXXFLAGS := $(CFLAGS) -std=c++17
# fortran
FC := gfortran
# copmilation flags (c, c++, fortran)
CPPFLAGS := -I $(INC_DIR) -DVERSION=1.0
# use this for shared libraries
# LDFLAGS := -shared -O2 -flto 
# use this for static libraries or executables
LDFLAGS := -O2 -flto

# ----- Target settings -----
ifeq ($(OS),Windows_NT)
	TARGET1 := target1.dll
	TARGET2 := target2.exe
	EXE_EXT := .exe
	OBJ_EXT := obj
	PLATFORM_DIR := windows
	NULL_DEVICE := NUL
else
	TARGET1 := target1.so
	TARGET2 := target2
	EXE_EXT := 
	OBJ_EXT := o
	PLATFORM_DIR := linux
	NULL_DEVICE := /dev/null
endif

BUILD_DIR := $(BUILD_DIR)/$(PLATFORM_DIR)
BIN_DIR := $(BIN_DIR)/$(PLATFORM_DIR)

SRC_FILES := $(wildcard $(SRC_DIR)/*.cpp)
# OBJ_FILES := $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.$(OBJ_EXT), $(SRC_FILES))
JSON_FILES := $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.json, $(SRC_FILES))
COMPILATION_DB := $(BUILD_DIR)/compile_commands.json

SRC_FILES_1 := $(SRC_DIR)/target_1.cpp
OBJ_FILES_1 := $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.$(OBJ_EXT), $(SRC_FILES_1))
SRC_FILES_2 := $(SRC_DIR)/target_2.cpp $(SRC_DIR)/target_2_main.cpp
OBJ_FILES_2 := $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.$(OBJ_EXT), $(SRC_FILES_2))

.PHONY: all clean compile_commands

# all: $(BIN_DIR)/$(TARGET) compile_commands
all : \
	$(BIN_DIR)/$(TARGET1) \
	$(BIN_DIR)/$(TARGET2) \
	compile_commands

$(BUILD_DIR):
	@echo "Creating build directory: $@"; \
	mkdir -p $@ && \
	echo '*' > $@/.gitignore

$(BIN_DIR):
	@echo "Creating bin directory: $@"; \
	mkdir -p $@ && \
	echo '*' > $@/.gitignore

# Compile each .cpp file to an object file
$(BUILD_DIR)/%.$(OBJ_EXT): $(SRC_DIR)/%.cpp | $(BUILD_DIR)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

# Link all object files into the shared library
# $(BIN_DIR)/$(TARGET): $(OBJ_FILES) | $(BIN_DIR)
# 	$(CXX) $(LDFLAGS) $^ -o $@
$(BIN_DIR)/$(TARGET1): $(OBJ_FILES_1) | $(BIN_DIR)
	$(CXX) $(LDFLAGS) -shared $^ -o $@
$(BIN_DIR)/$(TARGET2): $(OBJ_FILES_2) | $(BIN_DIR)
	$(CXX) $(LDFLAGS) $^ -o $@

# Compile each .cpp file to a JSON fragment
# $(BUILD_DIR)/%.json: $(SRC_DIR)/%.cpp | $(BUILD_DIR)
# 	$(CXX) $(CPPFLAGS) -MJ $@ -c $< -o $(NULL_DEVICE)
$(BUILD_DIR)/%.json: $(SRC_DIR)/%.cpp | $(BUILD_DIR)
	$(CXX) $(CPPFLAGS) -MJ $@ -c $< -o $(NULL_DEVICE)

./compile_commands.json: $(JSON_FILES)
	echo '[' > $(COMPILATION_DB)
	$(foreach file, $(JSON_FILES), cat $(file) >> $(COMPILATION_DB);)
	sed -i '$$ s/,$$//' $(COMPILATION_DB)
	echo ']' >> $(COMPILATION_DB)
	cp $(COMPILATION_DB) ./compile_commands.json

compile_commands: ./compile_commands.json

clean:
	rm -rf \
		$(BUILD_DIR)/* \
		$(BIN_DIR)/* \
		./compile_commands.json
