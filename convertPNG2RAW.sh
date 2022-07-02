#!/usr/bin/env bash

IMAGE=$1

if [ ${IMAGE}x == x ]; then
	echo "[ERROR] No image name provided"
	exit 1
fi

# Strip everything after the . (including the dot)
OUT=${IMAGE%%.*}

echo "Converting $IMAGE to $OUT.raw"

BYTES=$(identify -format "%[fx:h*w*2]" ${IMAGE})
convert ${IMAGE} -depth 16 pgm:- | tail -c $BYTES > $OUT.raw

