FROM pandoc/latex:latest

# Install additional LaTex packages
RUN tlmgr update --self
RUN tlmgr update --all
RUN tlmgr install cancel \
                  siunitx \
                  draftwatermark

ENTRYPOINT ["/data/render.sh"]
