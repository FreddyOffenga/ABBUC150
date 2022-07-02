#!/usr/bin/env bash

CODE=${1:-abbuc150}

mads -i:inc/ -o:${CODE}.xex ${CODE}.asm && Altirra64 ${CODE}.xex
