#!/bin/bash
if [ $DEBUG = true ]; then echo "# Running ${0}"; fi

GFX_PATH="funk_graphics"
GFX_FILE="funk_graphics/_funk_graphics.z80"

if ! [ -d "$GFX_PATH" ]; then
	# silent ignore
	exit
fi

# Tell father
echo "#define funkmake_graphics_success" >> $Temp

# create data file
echo "; Funk auto include graphics" > $GFX_FILE
echo ".nolist" >> $GFX_FILE
echo ".option bm_hdr = TRUE" >> $GFX_FILE
echo ".option bm_hdr_fmt=\"W,H\"" >> $GFX_FILE

# loop through bmps
images="$(ls $GFX_PATH/*.bmp 2> /dev/null)"
for image in $images ; do
	name=`basename $image .bmp`
	echo "gfx.$name" >> $GFX_FILE
	echo "#include \"$image\"" >> $GFX_FILE
done

# loop through folders, loop through contained bmps
folders="$(ls -d $GFX_PATH/*/ 2> /dev/null)"
for folder in $folders ; do
    folder=$(basename $folder)
	echo "gfx.$folder" >> $GFX_FILE
	images="$(ls $GFX_PATH/$folder/*.bmp)"
	for image in $images ; do
		name=`basename $image .bmp`
		echo "gfx.$folder.$name" >> $GFX_FILE
		echo "#include \"$image\"" >> $GFX_FILE
	done
done

echo ".option bm_hdr = FALSE" >> $GFX_FILE
echo ".list" >> $GFX_FILE