FROM grafana/grafana:13.2.1

COPY --chown=grafana grafana/provisioning /etc/grafana/provisioning
COPY --chown=grafana grafana/plugins /var/lib/grafana/plugins
COPY docker/entrypoint.sh docker/gitsync-bootstrap.sh docker/home-dashboard-bootstrap.sh /

ENTRYPOINT ["/entrypoint.sh"]
