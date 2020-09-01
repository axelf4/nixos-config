D := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

all: $(D)hardware-configuration.nix

$(D)hardware-configuration.nix:
	nixos-generate-config --dir $(D)

RULES := switch boot test build dry-build dry-activate build-vm build-vm-with-bootloader

$(RULES):
	nixos-rebuild $@ --flake $(D)#my-machine --show-trace

.PHONY: all $(RULES)
