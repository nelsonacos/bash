#!/bin/bash
# Cuenta los ficheros existentes dentro de una carpeta

function file_count() {
   local DIR=$1
   local NUMBER_OF_FILES=$(ls $DIR | wc -l)
   echo "${DIR}:"
   echo "$NUMBER_OF_FILES"
}

file_count $1
exit 0
