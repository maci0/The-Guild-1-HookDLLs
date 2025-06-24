# ---------------------
# Build Configuration
# ---------------------
TARGET          = x86-windows-gnu
CC              = zig cc -target $(TARGET)
AR              = zig ar
CFLAGS         += -Wall -O2 -fno-stack-protector

# ---------------------
# Directories
# ---------------------
SRC_DIR         = src
BUILD_DIR       = build
RELEASE_DIR     = release

MINHOOK_DIR     = vendor/minhook
MINHOOK_SRC     = $(MINHOOK_DIR)/src
MINHOOK_INC     = $(MINHOOK_DIR)/include
MINHOOK_LIB     = $(MINHOOK_DIR)/libminhook.lib

CFLAGS         += -I$(MINHOOK_INC)

# ---------------------
# Source & Target Files
# ---------------------
INJECTOR_SRC    = $(SRC_DIR)/injector.c
INJECTOR_EXE    = $(BUILD_DIR)/injector.exe

DLL_NAMES       = kernel32 server ws2_32
DLL_SRCS        = $(addprefix $(SRC_DIR)/,$(addsuffix _proxy.c,$(DLL_NAMES)))
DLL_TARGETS     = $(addprefix $(BUILD_DIR)/hook_,$(addsuffix .dll,$(DLL_NAMES)))

MINHOOK_SRCS    = \
	$(MINHOOK_SRC)/buffer.c \
	$(MINHOOK_SRC)/hde/hde32.c \
	$(MINHOOK_SRC)/hde/hde64.c \
	$(MINHOOK_SRC)/hook.c \
	$(MINHOOK_SRC)/trampoline.c

MINHOOK_OBJECTS = $(patsubst $(MINHOOK_DIR)/src/%.c,$(BUILD_DIR)/%.o,$(MINHOOK_SRCS))

# ---------------------
# Default Target
# ---------------------
all: submodule $(INJECTOR_EXE) $(DLL_TARGETS)

# ---------------------
# MinHook Static Library
# ---------------------
$(MINHOOK_LIB): $(MINHOOK_OBJECTS)
	@echo "Building MinHook static library..."
	$(AR) -rcs $@ $^

$(BUILD_DIR)/%.o: $(MINHOOK_SRC)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# ---------------------
# Injector Executable
# ---------------------
$(INJECTOR_EXE): $(INJECTOR_SRC)
	@echo "Compiling $< -> $@"
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $<

# ---------------------
# Proxies DLLs
# ---------------------
$(BUILD_DIR)/hook_%.dll: $(SRC_DIR)/%_proxy.c $(MINHOOK_LIB)
	@echo "Compiling $< -> $@"
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -shared -o $@ $< $(MINHOOK_LIB) -lshlwapi -lws2_32

# ---------------------
# Submodule Init
# ---------------------
submodule:
	@git submodule update --init --recursive

# ---------------------
# Install Artifacts
# ---------------------
install: all
	@echo "Installing artifacts to $(RELEASE_DIR)..."
	@mkdir -p $(RELEASE_DIR) $(RELEASE_DIR)/Server
	@cp $(INJECTOR_EXE) $(RELEASE_DIR)/
	@cp $(BUILD_DIR)/hook_*.dll $(RELEASE_DIR)/Server/
	@echo "Installation complete."

# ---------------------
# Package as Zip
# ---------------------
package: install
	@echo "Packaging release into The-Guild-1-HookDLLs.zip..."
	@cd $(RELEASE_DIR) && zip -r ../The-Guild-1-HookDLLs.zip .
	@echo "Packaging complete."

# ---------------------
# Cleanup
# ---------------------
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -f $(RELEASE_DIR)/injector.exe
	@rm -f $(RELEASE_DIR)/Server/hook_*.dll
	@rm -f $(MINHOOK_DIR)/libminhook.lib
	@rm -f The-Guild-1-HookDLLs.zip
	@echo "Clean complete."

# ---------------------
# Meta
# ---------------------
.PHONY: all clean install package submodule
.DELETE_ON_ERROR:
