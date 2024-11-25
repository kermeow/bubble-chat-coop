#!/bin/bash
# Build script for sm64coopdx mods

# Commands
LUAC32="../lua5.3.6/bin/luac32"
LUAC64="../lua5.3.6/bin/luac64"

# Constants
ROOT_DIR=$PWD
ASSETS_DIR=$ROOT_DIR/assets
SOURCE_DIR=$ROOT_DIR/src
OUTPUT_DIR=$ROOT_DIR/out

LUAC_FLAGS="$@"
export LC_COLLATE=C

# Check for necessary files
if [ ! -f ${SOURCE_DIR}/main.lua ]; then
    echo "main.lua is missing!"
    exit 1
fi

# Create output directory
if [ -d $OUTPUT_DIR ]; then
    if [ -f $OUTPUT_DIR/main.lua ]; then
        echo "Emptying old output folder"
        rm -r $OUTPUT_DIR/*
    fi
else
    echo "Creating new output folder"
    mkdir $OUTPUT_DIR
fi

# Copy non-lua assets
copy_assets()
{
    dir=$1
    if [ ! -d ${ASSETS_DIR}/${dir} ]; then
        return
    fi
    mkdir ${OUTPUT_DIR}/${dir}
    shift;
    for glob in $@; do
        if [ -n "$(find ${ASSETS_DIR}/${dir} -maxdepth 1 -name ${glob} -print -quit)" ]; then
            cp ${ASSETS_DIR}/${dir}/${glob} ${OUTPUT_DIR}/${dir}/
        fi
    done
}
echo "Copying actors"
copy_assets actors *.bin *.col
echo "Copying behaviors"
copy_assets data *.bhv
echo "Copying textures"
copy_assets textures *.tex
echo "Copying levels"
copy_assets levels *.lvl
echo "Copying sounds"
copy_assets sound *.m64 *.mp3 *.aiff *.ogg


# Copy main.lua
echo "Copying main.lua"
cp ${SOURCE_DIR}/main.lua ${OUTPUT_DIR}/

# Compile lua
echo "Compiling scripts"
compile()
{
    dir=$1
    prefix=$2
    for path in ${dir}/*.lua; do
        if [ ! -f $path ]; then
            continue
        fi
        file=$(basename -- $path)
        name=${file%.*}
        if [ "main" = $name ]; then
            continue
        fi
        if [ "_init" = $name ]; then
            name="__"
        fi
        output_file=${prefix}${name}
        if [ "--no-c" = "$(head -1 $path)" ]; then
            if [ -f $OUTPUT_DIR/$output_file ]; then
                continue
            fi
            output_file=${output_file}.lua
            echo "Copying ${file} > ${output_file} (no-c specified)"
            cp $path ${OUTPUT_DIR}/${output_file}
            continue
        fi
        output_file=${output_file}.luac
        echo "Compiling ${file} > ${output_file}"
        $LUAC $LUAC_FLAGS -o ${LUAC_DIR}/${output_file} -- $path
    done
    for subdir in ${dir}/*/; do
        if [ ! -d $subdir ]; then
            continue
        fi
        name=$(basename -- $subdir)
        echo "Compiling scripts from ${name} with flags ${LUAC_FLAGS}"
        prefix=$2
        compile ${subdir} ${prefix}${name}.
    done
}

# Compile for 64-bit
LUAC=$LUAC64
LUAC_DIR=$OUTPUT_DIR/c64

mkdir $LUAC_DIR
compile ${SOURCE_DIR} ""

echo "Compiling _mod_64.luac"
$LUAC $LUAC_FLAGS -o ${OUTPUT_DIR}/_mod_64.luac -- ${LUAC_DIR}/*.luac

# Compile for 32-bit
LUAC=$LUAC32
LUAC_DIR=$OUTPUT_DIR/c32

mkdir $LUAC_DIR
compile ${SOURCE_DIR} ""

echo "Compiling _mod_32.luac"
$LUAC $LUAC_FLAGS -o ${OUTPUT_DIR}/_mod_32.luac -- ${LUAC_DIR}/*.luac
