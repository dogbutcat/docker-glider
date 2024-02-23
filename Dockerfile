FROM alpine:3.19

RUN apk --no-cache add curl bash unzip base64

WORKDIR /root

ENV WORKDIR /root
ENV GLIDER_VERSION 0.16.3
ENV GLIDER_URL https://github.com/nadoo/glider/releases/download/v${GLIDER_VERSION}/glider_${GLIDER_VERSION}_linux_amd64v3.tar.gz

ENV VERBOSE True
ENV STRATEGY rr
ENV LISTEN :8443
ENV CHECK=http://www.msftconnecttest.com/connecttest.txt#expect=200

ENV SUBLINK ""
ENV TYPE ss
ENV COUNTRY ""
ENV MANUAL 0
ENV MANUAL_LINK ""
ENV MANUAL_LINK_BAK ""
ENV APPEND_LINK ""

ENV RENEW 0

RUN curl -sL $GLIDER_URL | busybox tar xvzf - \
	&& install glider_${GLIDER_VERSION}_linux_amd64v3/glider /usr/local/bin/

COPY ./start_glider.sh /root/start_glider.sh

ENTRYPOINT ["/root/start_glider.sh"]