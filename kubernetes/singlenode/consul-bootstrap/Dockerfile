FROM alpine:3.3
ENV CONSUL_URL ""
RUN apk --update add curl && rm -rf /var/cache/apk/*
COPY values /values
COPY add-values.sh /add-values.sh
RUN chmod +x /add-values.sh 
CMD ["/add-values.sh", "/values"]
