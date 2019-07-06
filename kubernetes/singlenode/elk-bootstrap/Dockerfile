FROM alpine:3.3
ENV ELK_URL ""
RUN apk --update add curl && rm -rf /var/cache/apk/*
COPY service-template.json /service-template.json
COPY add-template.sh /add-template.sh
RUN chmod 777 /add-template.sh
CMD ["/add-template.sh", "/service-template.json"]
