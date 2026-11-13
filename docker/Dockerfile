FROM grafana/grafana:13.3.1

# Grafana 13.3.0 dropped `bash` from its Alpine base image, but our entrypoint
# and bootstrap scripts rely on it.
USER root
RUN apk add --no-cache bash
USER grafana

COPY --chown=grafana grafana/provisioning /etc/grafana/provisioning
COPY --chown=grafana grafana/plugins /var/lib/grafana/plugins
COPY docker/entrypoint.sh docker/gitsync-bootstrap.sh docker/home-dashboard-bootstrap.sh /

ENTRYPOINT ["/entrypoint.sh"]
