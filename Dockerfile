FROM alpine:3.20

# Users install what they need via mounted setup scripts (install-*.sh / *.setup.sh).

WORKDIR /app

COPY run-scripts.sh defaultPoint.sh entrypoint.sh / 
COPY crontab.txt /app/crontab.txt

RUN sed -i 's/\r$//' /run-scripts.sh /defaultPoint.sh /entrypoint.sh /app/crontab.txt \
 && chmod +x /run-scripts.sh /defaultPoint.sh /entrypoint.sh \
 && mkdir -p /logger /sh-scripts

CMD ["/entrypoint.sh"]
