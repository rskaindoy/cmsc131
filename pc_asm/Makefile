UNAME := $(shell uname -s 2>/dev/null)

ifeq ($(OS),Windows_NT)
  PLATFORM := windows
else ifneq (,$(findstring MINGW,$(UNAME)))
  PLATFORM := windows
else ifneq (,$(findstring MSYS,$(UNAME)))
  PLATFORM := windows
else ifneq (,$(findstring CYGWIN,$(UNAME)))
  PLATFORM := windows
else
  PLATFORM := $(UNAME)
endif

NASM := nasm
CC   := gcc

ifeq ($(PLATFORM),windows)
  ASFLAGS := -f win32
  LDFLAGS := -Wl,-subsystem,console
  EXE     := .exe
else
  ASFLAGS := -f elf32 -d ELF_TYPE
  LDFLAGS := -no-pie
  EXE     :=
endif

CFLAGS := -m32

PROG ?= skel
BIN  := $(PROG)$(EXE)

$(BIN): $(PROG).obj asm_io.obj driver.o
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

%.obj: %.asm
	$(NASM) $(ASFLAGS) $< -o $@

driver.o: driver.c cdecl.h
	$(CC) $(CFLAGS) -c $< -o $@

run: $(BIN)
	./$(BIN)

STDIN := $(if $(wildcard $(PROG).input),< $(PROG).input,)

replay: $(BIN)
	@./$(BIN) $(STDIN)

check: $(BIN)
	@./$(BIN) $(STDIN) | diff -u --strip-trailing-cr --label "$(PROG).expected" --label "what $(PROG) printed" $(PROG).expected - && echo "OK: $(PROG) matches $(PROG).expected"

clean:
	rm -f *.obj *.o *.exe $(PROG)

.PHONY: run replay check clean