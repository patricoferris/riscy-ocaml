#!bin/bash


function build_gnu() {
	echo "Building RISCV-GCC... get a coffee or 10..."
	cd riscv-gnu
	./configure --prefix=/opt/riscv-gnu
	make newlib -j 2
	# make linux -j 2
}

function build_tools() {
	echo "Building SPIKE... probably don't need to get coffee..."
	export RISCV=/opt/riscv-spike
	cd /riscv-tools
	./build.sh
}

echo "Please specify what needs building"	
echo "1: GNU, 2: Tools, 3: Both, X: Neither"

read config

if [ "$config" -eq 1 ]
then
	build_gnu
elif [ "$config" -eq 2 ]
then
	build_tools
elif [ "$config" -eq 3 ]
then
	build_gnu
	build_tools
else
	echo "Have fun!"
fi

# Add things to path
export PATH=/opt/riscv-gnu/bin:$PATH
