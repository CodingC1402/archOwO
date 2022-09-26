#!/bin/bash

dir=$(dirname -- "$0")
echo "building from $dir"

workDir="${dir}/.build"
outDir="${dir}/.release"
profileDir="${dir}/src"
burnDisk=""

echo "Work: ${workDir}"
echo "Out: ${outDir}"
echo "Profile: ${profileDir}"

echo "options:"
echo "1) build"
echo "2) build and keep build files"
echo "3) build and burn"
echo "4) build, burn and keep build files"

read -r opt

rm -r "$workDir"
case $opt in
	1)
		;;
	2)
		;;
	3)
		echo "Disk to burn:"
		read -r burnDisk
		;;
	4)
		echo "Disk to burn:"
		read -r burnDisk
		;;
	*)
		;;
esac
		
echo "Construct work directory"
mkarchiso -v -w "$workDir" -o "$outDir" "$profileDir"

if [[ $opt == "1" ]] || [[ $opt == "3" ]]
then
	echo "Removing work directory..."
	rm -r $workDir
fi

if [[ $opt == "3" ]] || [[ $opt == "4" ]]
then
	dd bs=4M if=$(dirname "$0")/.release/archOwO-$(date +%Y.%m.%d)-x86_64.iso of=$burnDisk status=progress oflag=sync
fi
