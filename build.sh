dir=$(dirname -- "$0")
echo "building from $dir"

workDir="${dir}/.build"
outDir="${dir}/.release"
profileDir="${dir}/src"

echo "Work: ${workDir}"
echo "Out: ${outDir}"
echo "Profile: ${profileDir}"

echo "options:"
echo "1) update build"
echo "2) clean build"
echo "3) clear and clean build"

read opt

case $opt in
	1)
		;;
	2)
		rm -r $workDir
		;;
	3)
		rm -r $workDir
		rm -r $outDir
		;;
	*)
		;;
esac
		
mkarchiso -v -w $workDir -o $outDir $profileDir
