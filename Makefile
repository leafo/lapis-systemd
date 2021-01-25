.PHONY: test lint local build

test:
	busted

lint: build
	moonc -l lapis

local: build
	luarocks --lua-version=5.1 make --local lapis-systemd-dev-1.rockspec

build:
	moonc lapis
