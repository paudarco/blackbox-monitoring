FROM prom/alertmanager:v0.30.0

COPY --chmod=0755 docker/alertmanager/entrypoint.sh /usr/local/bin/alertmanager-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/alertmanager-entrypoint.sh"]