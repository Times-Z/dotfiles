#!/bin/bash

pacman -Qqen > pacman.txt

pacman -Qqem > yay.txt

echo "Files updated successfully"