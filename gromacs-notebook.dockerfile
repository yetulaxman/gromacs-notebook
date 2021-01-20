FROM gmxapi/ci-mpich:latest

RUN . $VENV/bin/activate && \
    pip install --no-cache-dir jupyter && \
    pip install matplotlib nglview requests pandas seaborn

ADD --chown=testing:testing notebook /docker_entry_points

CMD ["notebook"]
