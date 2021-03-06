# nasher
This is a command-line utility for managing a Neverwinter Nights script or
module repository.

## Contents

- [Description](#description)
- [Requirements](#requirements)
- [Installation](#installation)
    - [Docker](#docker)
- [Usage](#usage)
    - [Initializing a new package](#initializing-a-new-package)
    - [Listing build targets](#listing-build-targets)
    - [Building targets](#building-targets)
    - [Unpacking a file](#unpacking-a-file)
- [Configuration](#configuration)
- [Package Files](#package-files)
    - [Package Section](#package)
    - [Sources Section](#sources)
    - [Rules Section](#rules)
    - [Target Section](#target)

## Description
nasher is used to unpack an erf or module into a source tree, converting gff
files into json format. Since json is a text-based format, it can be checked
into git or another version-control system to track changes over time and make
it easier for multiple people to work on the same project simultaneously.
nasher can also rebuild the module or erf from those unpacked source files.

nasher is similar to [nwn-devbase](https://github.com/jakkn/nwn-devbase), but
it has some key differences:
1. nasher and the tools it uses are written in [nim](https://nim-lang.org)
   rather than Ruby, so they are much faster (handy for large projects) and can
   be distributed in binary form
2. nasher supports non-module projects (including erfs, tlks, and haks)
3. nasher supports multiple build targets (e.g., an installable erf and a demo
   module)
4. nasher supports custom source tree layouts (e.g., dividing scripts into
   directories based on category)
5. nasher can install built targets into the NWN installation directory
6. nasher uses json rather than yaml for storing gff files
7. nasher is known to run on Windows, but has not been thoroughly tested there

## Requirements
- [nim](https://github.com/dom96/choosenim) >= 1.2.0
- [neverwinter.nim](https://github.com/niv/neverwinter.nim) >= 1.2.10
- [nwnsc](https://github.com/nwneetools/nwnsc)

Alternatively, you can use [Docker](#docker).

## Installation
You can install nasher through `nimble`:

    # Install latest tagged version
    $ nimble install nasher

    # Install from master branch
    $ nimble install nasher@#head

Or by building from source:

    $ git clone https://github.com/squattingmonk/nasher.nim.git nasher
    $ cd nasher
    $ nimble install

Nasher should now be on your nimble path (~/.nimble/bin on Linux). To make it
easier to run nasher and other nim binaries, add this directory to your PATH.
The examples below assume you have done so.

### Docker
If you don't want to install Nim, you can instead use
[Docker](https://www.docker.com/products/docker-desktop). You can install
nasher using the `latest` tag, which installs the latest tagged version of
nasher, or with a version tag, such as `0.11.6` to use a particular tagged
version of nasher.

#### Example Usage
    # Linux, using latest tagged version
    $ docker run --rm -it -v $(pwd):/nasher nwntools/nasher:latest

    # Windows, using version 0.11.6
    $ docker run --rm -it -v %cd%:/nasher nwntools/nasher:0.11.6

#### Init example
If you are feeling particularly lazy, you can initialize the config file with
default settings:

    # Linux
    $ docker run --rm -it -v $(pwd):/nasher nwntools/nasher:latest init --default

    # Windows
    $ docker run --rm -it -v %cd%:/nasher nwntools/nasher:latest init --default

## Usage
Run `nasher --help` to see usage information. To get detailed usage information
on a particular command, run `nasher command --help`, where `command` is the
command you wish to learn about.

### Initializing a new package
    # Create a nasher package in the current directory
    $ nasher init

    # Create a nasher package in directory foo
    $ nasher init foo

This will create a `nasher.cfg` file in the package directory. You can alter
the contents of this file to customize the paths to sources, add author
information, etc.

The package directory will also be initialized as a git repository if it was
not already one. To avoid this behavior, pass `--vcs:none`.

### Listing build targets
    # List target names, descriptions, packed file, and source files
    $ nasher list

    # List target names only
    $ nasher list --quiet

This will list the targets available in the current package. The first target
listed is treated as the default.

### Building targets
When building a target, source files are cached into `.nasher/cache/x`, where
`x` is the name of the target. During later builds of this target, only the
source files that have changed will be rebuilt.

All of these commands accept multiple targets as parameters. In addition, you
can use the dummy target `all` to build all targets in the package.

    # Compile the "erf" and "demo" targets
    nasher compile erf demo

    # Compile all of the package's targets
    nasher compile all

The `convert`, `compile`, `pack`, and `install` commands are run in sequence.
If you want to install a target, you can just use the `install` command without
having to first use `convert`, `compile`, and `pack`.

You can skip particular steps of this sequence using the `--noConvert`,
`--noCompile`, `--noPack` or `--noInstall` commands. `--noPack` and
`--noInstall` imply `--noConvert` and `--noCompile`.

    # Install a previously packed file without rebuilding
    nasher install --noPack

All of these commands can delete the cache and trigger a clean build if passed
with `--clean`. `--clean` overrides `--noPack` and `--noInstall`.

#### convert
Converts all json sources for the target to gff format. It also caches non-json
source files for later packaging (useful for non-erf or non-module targets).

#### compile
Compiles all script sources for the target.

#### pack
Packs the converted and compiled resources into the target file. The packed
file is placed into the package root directory. If the file to be packed
already exists in the package root, you will be prompted to overwrite it. You
can force answer the prompt by passing the `--yes`, `--no`, or `--default`
flags.

#### install
Installs the packed file into the appropriate folder in the NWN installation
path. If the file to be installed already exists at the target location, you
will be prompted to overwrite it. You can force answer the prompt by passing
the `--yes`, `--no`, or `--default` flags.

### Launching a module
After installing a module target, you can launch the module to play. These
commands will first run the `convert->compile->pack->install` sequence, so
options that work for those will work here as well.

     # Play the module defined in the default target
     nasher play

     # Test the module defined in the "demo" target. This chooses the first PC
     # in the local vault, like launching from the toolset.
     nasher test demo

     # Load the file in nwserver for use in a multiplayer game
     nasher serve demo

### Unpacking a file
    # Unpack the default targets's installed file into the source tree
    $ nasher unpack

    # Unpack the demo target's installed file into the source tree
    $ nasher unpack demo

    # Unpack "demo.mod" into the demo target's source tree
    $ nasher unpack demo demo.mod

    # Unpack "demo.mod" into the default target's source tree
    $ nasher unpack --file:demo.mod

This unpacks a `.mod`, `.erf`, `.tlk`, or `.hak` file into the source tree. gff
and tlk files are are converted to json format. If a file does not exist in the
source tree, it is checked against a series of rules in the package config. If
a rule is matched, it will be placed in that directory. Otherwise, it is placed
into the directory `unknown` in the package root.

If an extracted file would overwrite a newer version, you will be prompted to
overwrite the file. You can force answer the prompt by passing the `--yes`,
`--no`, or `--default` flags.

If a file is present in the source tree but not in the file being extracted,
you will be asked if you want to remove the file from the source tree. This is
useful if you have deleted files from a module. You can pass the
`--removeDeleted` flag to skip this prompt:

    # Unpack "demo.mod", deleting files in src/ not present in "demo.mod"
    $ nasher unpack --file:demo.mod --removeDeleted

    # Unpack "demo.mod", but do not delete missing files from the source tree
    $ nasher unpack --file:demo.mod --removeDeleted:false

    # Make this project default to removing deleted files
    $ nasher config --local removeDeleted true

    # Make this project default to keeping deleted files
    $ nasher config --local removeDeleted false

You can initialize a package with the contents of a `.mod`, `.erf`, `.tlk` or
`.hak` file by running:

    # Initialize into foo using the contents of bar.mod as source files
    $ nasher init foo bar.mod

This is equivalent to:

    $ nasher init foo
    $ cd foo
    $ nasher unpack --file:../bar.mod

## Configuration
You can configure `nasher` using the `config` command (see `nasher config
--help` for detailed usage).

    # Set the default NWN installation path
    $ nasher config installDir "~/Documents/Neverwinter Nights"

Configuration options can also be passed to the commands directly using the
format `--option:value` or `--option:"value with spaces"`:

    # Compile with warnings on:
    $ nasher compile --nssFlags:"-loqey"

This syntax is also necessary in the `config` command when the value has words
beginning with a dash; otherwise these words are treated as options (a
limitation of the Nim parseopt module):

    # Incorrect
    $ nasher config nssFlags "-n /opts/nwn -owkey"

    # Correct
    $ nasher config --nssFlags:"-n /opts/nwn -owkey"

Currently, the following configuration options are available:

- `userName`: the default name to add to the author section of new packages
    - default: git user.name
- `userEmail`: the default email used for the author section
    - default: git user.email
- `nssCompiler`: the path to the script compiler
    - default (Posix): `nwnsc`
    - default (Windows): `nwnsc.exe`
- `nssFlags`: the default flags to use on packages
    - default: `-lowqey`
- `nssChunks`: the maximum number of scripts to process with one call to nwnsc
    - default: `500`
    - note: set this to a lower number if you run into errors about command
      lengths being too long.
- `erfUtil`: the path to the erf pack/unpack utility
    - default (Posix): `nwn_erf`
    - default (Windows): `nwn_erf.exe`
- `erfFlags`: additional flags to pass to the erf utility
    - default: ""
- `gffUtil`: the path to the gff conversion utility
    - default (Posix): `nwn_gff`
    - default (Windows): `nwn_gff.exe`
- `gffFlags`: additional flags to pass to the gff utility
    - default: ""
- `gffFormat`: the format to use to store gff files
    - default: `json`
    - supported: `json`
- `tlkUtil`: the path to the tlk conversion utility
    - default (Posix): `nwn_gff`
    - default (Windows): `nwn_gff.exe`
- `tlkFlags`: additional flags to pass to the tlk utility
    - default: ""
- `tlkFormat`: the format to use to store tlk files
    - default: `json`
    - supported: `json`
- `installDir`: the NWN user directory where built files should be installed
    - default (Linux): `~/.local/share/Neverwinter Nights`
    - default (Windows and Mac): `~/Documents/Neverwinter Nights`
- `gameBin`: the path to the nwmain binary (if not using default Steam path)
- `serverBin`: the path to the nwserver binary (if not using default Steam path)
- `vcs`: the version control system to use when making new packages
    - default: `git`
    - supported: `none`, `git`
- `removeUnusedAreas`: whether to prevent areas not present in the source files
  from being referenced in `module.ifo`.
    - default: `true`
    - note: you will want to disable this if you have some areas that are
      present in a hak or override and not the module itself.
- `useModuleFolder`: whether to use a subdirectory of the `modules` folder to
  store unpacked module files. This feature is useful only for NWN:EE users.
    - default: `true` during install; `true` during unpacking unless explicitly
      specifying a file to unpack
- `truncateFloats`: the max number of decimal places to allow after floats in
  gff files. Use this to prevent unneeded updates to files due to insignificant
  float value changes.
  - default: `4`
  - supported: `1` - `32`
- `modName`: the name for any module file to be generated by the target. This
  is independent of the filename. Only relevant when `convert` will be called.
  - default: ""
- `modMinGameVersion`: the minimum game version that can run any module file
  generated by the target. Only relevant when convert will be called.
  - default: ""
  - note: if blank, the version in the `module.ifo` file will be unchanged.

These options are meant to be separate from the package file (`nasher.cfg`)
since they may depend on the user.

## Package Files
A package file is a `nasher.cfg` file located in the package root. Package
files are used to specify the structure of the source tree and how to build
targets. Here is a sample package file:

``` ini
[Package]
name = "Core Framework"
description = "An extensible event management system for Neverwinter Nights"
version = "0.1.0"
author = "Squatting Monk <squattingmonk@gmail.com>"
url = "https://github.com/squattingmonk/nwn-core-framework"

[Sources]
include = "sm-utils/src/*.nss"
include = "src/**/*.{nss,json}"
exclude = "**/test_*.nss"

[Rules]
"hook_*.nss" = "src/Hooks"
"core_*" = "src/Framework"
"*" = "src"

[Target]
name = "default"
description = "An importable erf for use in new or existing modules"
file = "core_framework.erf"
exclude = "src/demo/**"
exclude = "**/test_*.nss"

[Target]
name = "demo"
description = "A demo module showing the system in action"
file = "core_framework.mod"
modName = "Core Framework Demo Module"
modMinGameVersion = "1.69"

[Target]
name = "scripts"
description = "A hak file containing compiled scripts"
file = "core_scripts.hak"
include = "src/**/*.nss"
filter = "*.nss"
```

While you can write your own package file, the `init` command will create one
for you. It will show prompts for each section and provide useful defaults. If
you don't want to answer the prompts and just want to quickly initialize the
package, you can pass the `--default` flag when running `init`.

### Package
This section is optional. In the future, this information will be used to
publish packages for easy discovery and installation.

- `name`: a brief name for the package
- `description`: a description of the package. You can use `"""triple
  quotes"""` to enable multi-line descriptions.
- `version`: the package version
- `author`: the name and email of the package author. This field can be
  repeated if there are multiple authors; each author gets their own line.
- `url`: the location where the package can be downloaded
- `modName`: the default name for a module generated by a target. This is
  independent of the filename. If unset, will use the name listed in the
  `module.ifo`'s source file.
- `modMinGameVersion`: the default minimum game version that can run a module
  generated by a target. If unset, will use the version listed in the
  `module.ifo`'s source file.

### Sources
This section is required. It describes the layout of the source tree. All paths
are relative to the package root.

- `include`: a glob pattern matching files to include (e.g.,
  `src/**/*.{nss,json}` to match all nss and json files in `src` and its
  subdirectories). This field can be repeated.
- `exclude`: a glob pattern matching files to exclude from sources. This field
  can be repeated.
- `filter`: a glob pattern matching files to remove before packing. It operates
  on converted files in the cache, not source files, so it should not contain
  any directory information. Use this to include files that are needed for
  compilation but should not be included in the final file. This field can be
  repeated.

When nasher looks for sources, it first finds all files that match any include
pattern and then filters out files that match any exclude pattern. In the
example package file, all nss and json files in `src` and its subdirectories
are included, except for those nss files that begin with `test_`.

### Rules
This section is optional. It tells nasher where to place extracted files that
do not already exist in the source tree. Rules take the form `"pattern" =
"path"`, where `pattern` is a glob pattern matching the filename and `path` is
the folder into which it should be placed. All paths are relative to the
package root.

When unpacking, nasher checks each extracted file against the source tree. If
the file does not exist in the source tree, it will be checked against each
rule. If `pattern` matches the filename, the file will be extracted to `path`.
If no pattern matches the filename, it will be placed into a directory called
`unknown` in the package root so the user can manually copy the file to the
proper place later.

In the example package file, nss files beginning with `hook_` are placed in
`src/Hooks`, all files beginning with `core_` are placed in `src/Core`, and all
other files are placed in `src`.

### Target
At least one target section is required. It is used to provide the name,
description, output file, and sources of each build target. This section can be
repeated, specifying a different target each time.

- `name`: the name of the target. This will be passed to the `convert`,
  `compile`, `pack`, and `install` commands. Each target must have a unique
  name.
- `file`: the name of the file that will be created, including the file
  extension.
- `description`: a description of the output file. This field is optional, but
  is recommended if your package has multiple build targets.
- `modName`: the default name for a module generated by the target. This is
  independent of the filename. If unset, will inherit from the package section.
- `modMinGameVersion`: the default minimum game version that can run a module
  generated by the target. If unset, will inherit from the package section.
- `include`: a glob pattern matching source files to be used for this target.
  This field is optional. If supplied, this target will use only the supplied
  source files; otherwise, the target will use all source files included by the
  package. This field can be repeated.
- `exclude`: a glob pattern matching files to exclude from the sources for this
  target. This field is optional. If supplied, this target will exclude only
  those files that match the supplied patterns; otherwise, the target will
  exclude all files excluded by the package. This field can be repeated.
- `filter`: a glob pattern matching files to remove before packing. It operates
  on converted files in the cache, not source files, so it should not contain
  any directory information. Use this to remove files that are needed for
  compilation but should not be included in the final file. This field is
  optional. If supplied, this target will filter only those files that match
  the supplied patterns; otherwise, the target will filter all files filtered
  by the package. This field can be repeated.
- Any other key under the target will be treated as an unpack rule for that
  target. In unpack rules, they key is a pattern to match the file against
  while the key is a directory in which to place the file. You can have any
  number of unpack rules. If a target does not contain its own unpack rules, it
  will inherit those of the package. If the target file is being unpacked and a
  file is encountered which is not in the target's source tree, the filename
  will be checked against each pattern in the source tree; when a matching
  pattern is found, the file will be placed in the directory assigned to that
  pattern.

In the example package file, the `demo` target will use the package `include`
and `exclude` fields since it did not specify its own. However, the `default`
target excludes files in `src/demo` and its subdirectories; since it overrides
the package `exclude`, it needs to repeat the `exclude` line from the package
to avoid accidentally including nss files beginning with `test_`.

Meanwhile, the `scripts` target will include all `.nss` files, but will filter
them out after compilation and before packing, leaving only the compiled `.ncs`
files behind.
