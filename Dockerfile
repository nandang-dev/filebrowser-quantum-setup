FROM gtstef/filebrowser:1.5.8-stable

USER root
COPY --chown=1000:1000 config.yaml /home/filebrowser/data/config.yaml
USER filebrowser
