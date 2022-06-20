# patchkit-tools
PatchKit command line tools.

Read about it [here](https://docs.patchkit.net/tools_about.html).

## Packaging

Requirements:

- POSIX environment (Linux, OSX or Windows with Linux subsystem)
- docker
- make

Execute `make build`. Result will be placed at `packaging/output`.

## Known Bugs
- Warnings on Windows packaged version of tools are disabled (because of warnings of redefined constants from Fiddle)
