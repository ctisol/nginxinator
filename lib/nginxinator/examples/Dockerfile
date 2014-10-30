# vi: ft=config
FROM ubuntu:12.04
MAINTAINER david amick <docker@davidamick.com>

ENV DEBIAN_FRONTEND noninteractive

RUN /bin/bash -l -c "apt-get update -qq && apt-get install -qy nginx"

ENTRYPOINT ["/usr/sbin/nginx"]
CMD ["-c", "/etc/nginx/nginx.conf"]
