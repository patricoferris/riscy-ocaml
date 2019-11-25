# RISCY-OCaml

This repository holds the dockerfile and related bash scripts for developing with OCaml and RISC-V, in particular modifiying the compiler pipeline. It was born out of my Part II CST project of adding custom instructions for OCaml-specfic patterns to the pipeline. 

The main pain is that in order to add custom instructions you need to make three modifications:

1. To `riscv-ocaml` the ocaml compiler which emits the assembly 
2. To `riscv-gcc` which takes the ouput assembly from something like `ocamlopt` and produces the binary executables
3. To `riscv-spike` the ISA simulator for RISC-V to make sure your code is working

This dockerfile aims to get all of those moving parts into one place but also allow you to easily modify the existing code and re-build so you can make some progress!

Setup
-------

In order for this to work you need the following directory structure

```text
|- riscv-gnu-toolchain
|- riscv-tools
|- riscv-ocaml-code
|- riscy-ocaml
	|- build.sh
	|- dockerfile
	|- dockerrun.sh
```

To get the gnu-toolchain and ISA simulator you can run the following commands:

```
git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
git clone https://github.com/riscv/riscv-tools.git
```

*Note the toolchain is HUGE and takes ages to build*

You should then be able to `cd` into `riscy-ocaml` and run the following commands.

```bash 
docker build . -t riscy-ocaml
./dockerrun.sh

# Now inside the docker container
# Build script will prompt you for a configuration which it explains
./build.sh 
```

Compiling Code
--------------

The build will take quite a long time so do find something else to do whilst that happens. Once it is built the binaries should be in `/opt/riscv-gnu` and `/riscv-spike/build` respectively which have been mounted with directories `riscv-gnu-bin` and the `riscv-tools` next to `riscy-ocaml`.


A simple demo then looks something like the following:

```
echo "let () = print_endline 'Hello World\n'" > hello.ml
ocamlopt -ccopt -static -S -o hello.out hello.ml
/riscv-spike/build/spike /usr/local/riscv64-unknown-elf/bin/pk  hello.out
```

Customised Instructions
-------------

This a multi-step process largely based on [this great article](https://nitish2112.github.io/post/adding-instruction-riscv/). Follow the article to update all of the different tools which includes:
1. `riscv-opcodes` in `riscv-tools`
2. `riscv-isa-sim` in `riscv-tools` - *note the `disasm.cc` file does NOT need changing`*
3. `riscv-gnu-toolchain` - the file names are slightly different but should be straight-forward enough. 

When it comes to actually trying to compile all this - the simplest way to get some output is to generate the `.s` RISC-V assembly file, manually changed the instructions and then try and used the gnu compiler to take that file down to the `.out` file that Spike can then simulate.

The general formula I have been using is the following: 

```bash
# First compile the code exposing the startup magic and the assembly
ocamlopt -dstartup -ccopt -static -S -o example.out example.ml -verbose

# Then create a new custom directory and copy in the necessary files
mkdir custom
cp example.s ./custom/example_custom.s
mv example.out.startup.s ./custom

# Modify the example_custom.s file to use custom instructions
# Then use the assembly compiler to produce an object file of that 
/opt/riscv-gnu/bin/riscv64-unknown-linux-gnu-as -o 'example_custom.o' 'example_custom.s'

# Also create the startup object file 
/opt/riscv-gnu/bin/riscv64-unknown-linux-gnu-as -o 'camlstartup203a86.o' 'example.out.startup.s'

# Compile the whole thing and then run it through spike
riscv64-unknown-linux-gnu-gcc -Os -fno-strict-aliasing -fwrapv -Wall -Werror -D_FILE_OFFSET_BITS=64 -D_REENTRANT -DCAML_NAME_SPACE  -Wl,-E -o 'example.out'   '-L/riscv-ocaml/lib/ocaml' -static '/tmp/camlstartup203a86.o' '/riscv-ocaml/lib/ocaml/std_exit.o' 'example_custom.o' '/riscv-ocaml/lib/ocaml/stdlib.a' '/riscv-ocaml/lib/ocaml/libasmrun.a' -lm  -ldl
```

