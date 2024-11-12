FROM grafana/grafana:11.3.0

COPY grafana/provisioning /etc/grafana/provisioning
COPY grafana/plugins /var/lib/grafana/plugins
COPY docker/entrypoint.sh /

USER grafana
EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
