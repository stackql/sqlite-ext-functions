# Copyright (c) 2024 StackQL Studios, MIT License
# https://github.com/stackql

.PHONY: prepare-dist compile-linux compile-windows compile-macos test-all test clean

SQLITE_RELEASE_YEAR := 2024
SQLITE_VERSION := 3460000

SRC_DIR = src
DIST_DIR = dist

# Determine platform-specific variables
ifeq ($(OS),Windows_NT)
    LOAD_SCRIPT = test/inc/load_ext_windows.sql
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Darwin)
        LOAD_SCRIPT = test/inc/load_ext_darwin.sql
    else
        LOAD_SCRIPT = test/inc/load_ext_linux.sql
    endif
endif

prepare-dist:
	mkdir -p $(DIST_DIR)
	rm -rf $(DIST_DIR)/*

download-sqlite:
	curl -L https://www.sqlite.org/$(SQLITE_RELEASE_YEAR)/sqlite-amalgamation-$(SQLITE_VERSION).zip --output src.zip
	unzip src.zip
	mv sqlite-amalgamation-$(SQLITE_VERSION)/* $(SRC_DIR)
	rm -rf sqlite-amalgamation-$(SQLITE_VERSION)
	rm src.zip

compile-linux:
	gcc -O2 -fPIC -shared -I$(SRC_DIR) $(SRC_DIR)/json_equal/*.c -o $(DIST_DIR)/json_equal.so -lsqlite3
	gcc -O2 -fPIC -shared -I$(SRC_DIR) $(SRC_DIR)/regexp/*.c -o $(DIST_DIR)/regexp.so -lsqlite3
	gcc -O2 -fPIC -shared -I$(SRC_DIR) $(SRC_DIR)/split_part/*.c -o $(DIST_DIR)/split_part.so -lsqlite3

compile-windows:
	gcc -O2 -shared -Isrc src/json_equal/*.c -o dist/json_equal.dll
	gcc -O2 -shared -Isrc src/regexp/*.c -o dist/regexp.dll
	gcc -O2 -shared -Isrc src/split_part/*.c -o dist/split_part.dll

compile-macos:
	gcc -O2 -fPIC -dynamiclib -Isrc src/json_equal/*.c -o dist/json_equal.dylib
	gcc -O2 -fPIC -dynamiclib -Isrc src/regexp/*.c -o dist/regexp.dylib
	gcc -O2 -fPIC -dynamiclib -Isrc src/split_part/*.c -o dist/split_part.dylib

test-all:
	@echo "Running tests on all suites"
	@make test suite=json_equal
	@make test suite=regexp
	@make test suite=split_part

# fails if grep does find a failed test case
test:
	@echo "Testing suite: $(suite)"
	@sqlite3 -init $(LOAD_SCRIPT) < test/$(suite).sql > test.log
	@cat test.log | (! grep -Ex "[0-9_]+.[^1]")

clean:
	rm -f $(DIST_DIR)/*.so
	rm -f $(DIST_DIR)/*.dll
	rm -f $(DIST_DIR)/*.dylib
	rm -f test.log
