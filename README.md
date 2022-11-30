# nixos-config

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)
![check](https://github.com/axelf4/nixos-config/workflows/check/badge.svg)

## Steam

The Sid Meier's Civilization VI launcher does not start on Linux, but
it can be bypassed by opening the `Civ6` file and changing

    ./GameGuide/Civ6

to

    ./Civ6Sub
