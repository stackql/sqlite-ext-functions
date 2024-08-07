# Copyright (c) 2024 StackQL Studios, MIT License
# https://github.com/stackql

.PHONY: prepare-dist compile-linux compile-windows compile-macos test-all test clean

SQLITE_RELEASE_YEAR := 2024
SQLITE_VERSION := 3460000

SRC_DIR = src
DIST_DIR = dist

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

compile-macos-x86:
	gcc -O2 -fPIC -dynamiclib -Isrc -target x86_64-apple-macos12 src/json_equal/*.c -o dist/json_equal_x86.dylib
	gcc -O2 -fPIC -dynamiclib -Isrc -target x86_64-apple-macos12 src/regexp/*.c -o dist/regexp_x86.dylib
	gcc -O2 -fPIC -dynamiclib -Isrc -target x86_64-apple-macos12 src/split_part/*.c -o dist/split_part_x86.dylib

compile-macos-arm64:
	gcc -O2 -fPIC -dynamiclib -Isrc -target arm64-apple-macos12 src/json_equal/*.c -o dist/json_equal_arm64.dylib
	gcc -O2 -fPIC -dynamiclib -Isrc -target arm64-apple-macos12 src/regexp/*.c -o dist/regexp_arm64.dylib
	gcc -O2 -fPIC -dynamiclib -Isrc -target arm64-apple-macos12 src/split_part/*.c -o dist/split_part_arm64.dylib

compile-macos-universal: compile-macos-x86 compile-macos-arm64
	lipo -create -output dist/json_equal.dylib dist/json_equal_x86.dylib dist/json_equal_arm64.dylib
	lipo -create -output dist/regexp.dylib dist/regexp_x86.dylib dist/regexp_arm64.dylib
	lipo -create -output dist/split_part.dylib dist/split_part_x86.dylib dist/split_part_arm64.dylib
	rm -f dist/json_equal_x86.dylib dist/json_equal_arm64.dylib
	rm -f dist/regexp_x86.dylib dist/regexp_arm64.dylib
	rm -f dist/split_part_x86.dylib dist/split_part_arm64.dylib

pack-linux:
	zip -j dist/stackql-sqlite-ext-functions-linux-amd64.zip dist/*.so

pack-windows:
	zip -j dist/stackql-sqlite-ext-functions-windows-amd64.zip dist/*.dll

pack-macos-universal:
	zip -j dist/stackql-sqlite-ext-functions-macos-universal.zip dist/*.dylib

test-all:
	@echo "Running tests on all suites"
	@make test suite=json_equal
	@make test suite=regexp
	@make test suite=split_part

# fails if grep does find a failed test case
test:
	@echo "Testing suite: $(suite)"
	@sqlite3 < test/$(suite).sql > test.log
	@cat test.log | (! grep -Ex "[0-9_]+.[^1]")

clean:
	rm -f $(DIST_DIR)/*.so
	rm -f $(DIST_DIR)/*.dll
	rm -f $(DIST_DIR)/*.dylib
	rm -f test.log
