#!/bin/bash

docker run -v `pwd`/../riscv-gnu-toolchain:/riscv-gnu -v `pwd`/../riscv-tools:/riscv-tools -v `pwd`/../riscv-gnu-bin:/opt/riscv-gnu -v `pwd`/../riscv-spike-bin:/opt/riscv-tools/ -v `pwd`/../riscv-ocaml-code:/tmp/code -it riscy-ocaml
