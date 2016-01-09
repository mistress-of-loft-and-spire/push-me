#!/bin/sh
git pull
git add .
git commit -m "auto-commit on `date +'%Y-%m-%d %H:%M:%S'`";
git push