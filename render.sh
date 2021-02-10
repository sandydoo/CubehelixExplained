#!/bin/sh

pandoc \
  --pdf-engine xelatex \
  --output rendered/CubehelixExplained.pdf \
  CubehelixExplained.md

pandoc \
  --standalone \
  --mathjax \
  --output rendered/index.html \
  CubehelixExplained.md
