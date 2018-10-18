SUFFIX   = .cpp
SRCDIR   = ./src
LIBDIR   = ./lib
INCLUDEDIR   = ./include
RELEASEDIR   = ./release

CXX ?= g++
CXX_WIN_I686 ?= i686-w64-mingw32-g++
CXX_WIN_AMD64 ?= x86_64-w64-mingw32-g++
CXX_LINUX_I686 ?= i686-linux-gnu-g++
CXX_LINUX_ARMHF ?= arm-linux-gnueabihf-g++
CXX_LINUX_ARM64 ?= aarch64-linux-gnu-g++
CPPFLAGS ?= -Wall -Ofast -s -Wl,--gc-sections -ffunction-sections -fdata-sections
CXXFLAGS ?= -std=c++11
INCLUDEDIR_ARGS ?= -I$(INCLUDEDIR)
LIBDIR_ARGS ?= 
LIB_ARGS ?= -lexec-stream -lpthread

SOURCES  = $(wildcard $(SRCDIR)/*$(SUFFIX))#./src/git-set-file-times.cpp
TARGETS  = $(notdir $(basename $(SOURCES)))#git-set-file-times
MKDIRP = mkdir -p

all: linux windows
linux: linux/i686 linux/amd64 linux/armhf linux/arm64
windows: windows/i686 windows/amd64

define BUILD_TPL
	$(eval SRC_FILENAME = $(1))
	$(eval DEST_ARCH = $(2))
	$(eval DEST_PREFIX = $(3))
	$(eval USE_CXX = $(4))
	$(eval OPTIONAL_ARGS = $(5))
	$(eval OUTFILE = $(RELEASEDIR)/$(DEST_ARCH)/$(notdir $(basename $(SRC_FILENAME)))$(DEST_PREFIX))
	$(eval OUTFILE_STATIC = $(RELEASEDIR)/$(DEST_ARCH)_static/$(notdir $(basename $(SRC_FILENAME)))$(DEST_PREFIX))
	$(MKDIRP) $(LIBDIR)/$(DEST_ARCH) && $(MKDIRP) $(dir $(OUTFILE)) && $(MKDIRP) $(dir $(OUTFILE_STATIC))
	[ -e $(INCLUDEDIR)/exec-stream.h ] || cp deps/libexecstream/exec-stream.h $(INCLUDEDIR)/
	$(USE_CXX) -static $(OPTIONAL_ARGS) $(CXXFLAGS) $(CPPFLAGS) -c -o $(LIBDIR)/$(DEST_ARCH)/exec-stream.o deps/libexecstream/exec-stream.cpp
	ar rcs $(LIBDIR)/$(DEST_ARCH)/libexec-stream.a $(LIBDIR)/$(DEST_ARCH)/exec-stream.o
	$(USE_CXX) $(OPTIONAL_ARGS) $(CXXFLAGS) $(CPPFLAGS) -o $(OUTFILE) -L$(LIBDIR)/$(DEST_ARCH) $(LIBDIR_ARGS) $(INCLUDEDIR_ARGS) $(SRC_FILENAME) $(LIB_ARGS)
	$(USE_CXX) -static $(OPTIONAL_ARGS) $(CXXFLAGS) $(CPPFLAGS) -o $(OUTFILE_STATIC) -L$(LIBDIR)/$(DEST_ARCH) $(LIBDIR_ARGS) $(INCLUDEDIR_ARGS) $(SRC_FILENAME) $(LIB_ARGS)
endef
#build *.so(if you need)
#$(USE_CXX) -shared -fPIC $(OPTIONAL_ARGS) $(CXXFLAGS) $(CPPFLAGS) -o $(LIBDIR)/$(DEST_ARCH)/libexec-stream.so deps/libexecstream/exec-stream.cpp

linux/i686: $(SRCDIR)/$(TARGETS).cpp
	$(call BUILD_TPL,$^,$@,,$(CXX_LINUX_I686),)

linux/amd64: $(SRCDIR)/$(TARGETS).cpp
	$(call BUILD_TPL,$^,$@,,$(CXX),-m64)

linux/armhf: $(SRCDIR)/$(TARGETS).cpp
	$(call BUILD_TPL,$^,$@,,$(CXX_LINUX_ARMHF),)

linux/arm64: $(SRCDIR)/$(TARGETS).cpp
	$(call BUILD_TPL,$^,$@,,$(CXX_LINUX_ARM64),)

windows/i686: $(SRCDIR)/$(TARGETS).cpp
	$(call BUILD_TPL,$^,$@,.exe,$(CXX_WIN_I686),)

windows/amd64: $(SRCDIR)/$(TARGETS).cpp
	$(call BUILD_TPL,$^,$@,.exe,$(CXX_WIN_AMD64),)

