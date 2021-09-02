# Model Picture Paradigm

This project consists of two tasks. The first presents 115 images of models categorized as thin (38), average (39), or overweight (38). Attractiveness ratings are collected for each model. A random subset of 20 images is selected from each category for use in during the second task.  

## Required software

MATLAB release: R2017b  

Packages: [Psychtoolbox](http://psychtoolbox.org/download#Mac)  

## Endpoints

### /

`PicRatings_Model_BRF.m`: Run this script first to collect image ratings.

`SimpleExposure_Mod.m`: This task uses 20 randomly selected images from each of the three conditions (thin, average, overweight).

### /Pics

Populate this folder with pictures for use with the task scripts.
