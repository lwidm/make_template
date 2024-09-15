# Makefile

BUILD_DIR := build
BIN_DIR := bin
SRC_DIR := src
INC_DIR := include

# Compiler settings
CC := clang
CXX := clang++
CPPFLAGS := -I $(INC_DIR) -DVERSION=1.0
CFLAGS := -O2
CXXFLAGS := $(CFLAGS) -std=c++17
LDFLAGS := -shared -O2 -flto

# Target settings
ifeq ($(OS),Windows_NT)
	TARGET := lw_cpp_ctypes.dll
	EXE_EXT := .exe
	OBJ_EXT := obj
	PLATFORM_DIR := windows
	NULL_DEVICE := NUL
else
	TARGET := lw_cpp_ctypes.so
	EXE_EXT := 
	OBJ_EXT := o
	PLATFORM_DIR := linux
	NULL_DEVICE := /dev/null
endif

BUILD_DIR := $(BUILD_DIR)/$(PLATFORM_DIR)
BIN_DIR := $(BIN_DIR)/$(PLATFORM_DIR)

SRC_FILES := $(wildcard $(SRC_DIR)/*.cpp)
OBJ_FILES := $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.$(OBJ_EXT), $(SRC_FILES))
JSON_FILES := $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.json, $(SRC_FILES))
COMPILATION_DB := $(BUILD_DIR)/compile_commands.json

.PHONY: all clean compile_commands

all: $(BIN_DIR)/$(TARGET) compile_commands

$(BUILD__DIR):
	mkdir -p $@

$(BUILD_DIR)/.gitignore:
	echo '*' > $@

$(BIN_DIR):
	mkdir -p $@

# Compile each .cpp file to an object file
$(BUILD_DIR)/%.$(OBJ_EXT): $(SRC_DIR)/%.cpp | $(BUILD_DIR)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

# Link all object files into the shared library
$(BIN_DIR)/$(TARGET): $(OBJ_FILES) | $(BIN_DIR)
	$(CXX) $(LDFLAGS) $^ -o $@

# Compile each .cpp file to a JSON fragment
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
		$(BUILD_DIR)/*.$(OBJ_EXT) \
		$(BIN_DIR)/$(TARGET) \
		$(BIN_DIR)/*.lib \
		$(BIN_DIR)/*.exp \
		$(BUILD_DIR)/*.json \
		./compile_commands.json
