#!/bin/bash
echo -e "\e[1;33m# Starting Funk build script...\e[0m"


#export DEBUG=true


#====================================
# GET PARAMETERS / CONFIG
#====================================
if [ "${1: -7}" == ".config" ]; then
	ConfigFile=$1
else
	if [ -r "${1%.*}.config" ]; then
		ConfigFile=${1%.*}.config
	else
		ConfigFile=funk.config
	fi
fi

Options=""

if [ -r "$ConfigFile" ]; then
	# Read config file
	echo "# Using config file \"${ConfigFile}\""
    DONE=false
    until $DONE; do
    	read line || DONE=true
        if [ "$line" = "" ]; then continue; fi
        key=$(echo $line | cut -d "=" -f 1 -s | tr -d "\r" | sed -e 's/^ *//' -e 's/ *$//');
        value=$(echo $line | cut -d "=" -f 2 -s | tr -d "\r" | sed -e 's/^ *//' -e 's/ *$//');
        if [ "$key" = "" -o "$value" = "" ]; then
            key=$(echo $line | tr -d " ");
            value=true
        fi
        export $key="$value"
    done < $ConfigFile
fi

if [ -z $DEBUG ]; then export DEBUG=false; fi
if [ $DEBUG = true ]; then echo -e "\e[1;33m# Debug mode\e[0m"; fi

if [ -n "$Folder" ]; then
	ORIG_CD=$(pwd)
	cd $Folder
fi

if [ -z "$Source" ]; then
	if [ -n "$1" ]; then
		if [ "$ConfigFile" = "$1" ]; then
			echo -e "\e[1;31mError: Source is not defined in config file\e[0m"; exit
		fi
		Source=$1
	else
		# Try finding lonely source file
		file=`ls | grep -v "^_" | grep "\.asm$\|\.z80$"`
		num=`ls | grep -v "^_" | grep "\.asm$\|\.z80$" | wc -l`
		if [ $num = 1 ]; then
			# Set name if found
			Source=$file
		else
			echo -e "\e[1;31mError: Source file is not inferable\e[0m"; exit
		fi
	fi
fi

if ! [ -r "$Source" ]; then
	echo -e "\e[1;31mError: File \"${Source}\" not found\e[0m"; exit
fi

if [ -z "$Type" ]; then
	if [ -n "$2" ]; then
		Type=$2
	else
		Type=nostub
	fi
fi

if [ -z "$Calc" ]; then
	if [ -n "$3" ]; then
		Calc=$3
	else
		Calc=ti83p
	fi
fi

if [ -z "$Name" ]; then
	if [ -n "$4" ]; then
		Name=$4
	else
		Name=${Source%.*} # remove extension
	fi
fi

if [ -z "$Target" ]; then
	if [ -n "$5" ]; then
		Target=$5
	else
		Target=$Name
	fi
fi
if [ "$Type" = "app" ]; then
	Target="${Target}.8xk"
else
	if [ "$Calc" = "ti83" ]; then
		Target="${Target}.83p"
	else
		Target="${Target}.8xp"
	fi
fi


#====================================
# PREPARE
#====================================
echo "# Preparing \"${Name}\", running scripts ..."

if [ -n "$Folder" ]; then
	cd $ORIG_CD
fi

export Temp="_funk_temp.z80"
export FunkPath="$(cd "$( dirname "$0" )" && pwd)"

if [ -n "$Folder" ]; then
	cd $Folder
fi

if [ "$(uname -o)" = "Cygwin" ]; then
	Platform="win"
	FUNK_PATH="$(cygpath -w -a ${FunkPath})"
	FUNK_PATH="${FUNK_PATH//\\//}"
else
	Platform="linux"
	FUNK_PATH=$FunkPath
fi

echo ";* Funk temporary compile file" > $Temp
if [ $DEBUG = true ]; then echo "#define FUNK_DEBUG" >> $Temp; fi
echo "#define FUNK_PATH \"${FUNK_PATH}/\"" >> $Temp
echo "#include \"${FUNK_PATH}/funk.z80\"" >> $Temp


#====================================
# RUN FUNKY SCRIPTS
#====================================
files=`ls $FunkPath/scripts | grep "\.sh$"`
for file in $files ; do
	sh "$FunkPath/scripts/$file"
done


#====================================
# RUN LOCAL SCRIPTS
#====================================
if [ -d "funk_execute" ]; then
	files=`ls funk_execute | grep "\.sh$"`
	for file in $files ; do
		sh funk_execute/$file
	done
fi


#====================================
# FUNKY ENCLOSURE / INCLUDE
#====================================
echo ".funk \"${Name}\", ${Type}, ${Calc}" >> $Temp

# include folder "funk_header"
if [ -d "funk_header" ]; then
	files=`ls funk_header | grep "\.asm$\|\.z80$"`
	for file in $files ; do
		echo "#include \"funk_header/${file}\"" >> $Temp
	done
fi

echo "#include \"${Source}\"" >> $Temp
echo ".funkend" >> $Temp


#====================================
# COMPILE
#====================================
if [ "$(uname -m)" = "x86_64" ]; then
	Bit="64"
else
	Bit="32"
fi

Compiler="${FunkPath}/spasm/spasm-${Platform}${Bit}"

if [ $DEBUG = true ]; then
	echo "Debug: Compiling \"spasm-${Platform}${Bit} ${Source} ${Target} ${Options}\""
fi

"$Compiler" "$Temp" "$Target" $Options

if [ -n "$Folder" ]; then
	cp $Target $ORIG_CD/$Target
fi


#====================================
# CLEAN
#====================================
if [ $DEBUG = false ]; then
	rm -f _funk_data.z80
	rm -f _funk_header.z80
	rm -f _funk_rmayed.z80
	rm -f _funk_setup.z80
	rm -f _funk_include.z80
	rm -f _temp.z80
	rm -f $Temp
fi
