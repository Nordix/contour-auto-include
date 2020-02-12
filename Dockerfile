FROM alpine:latest
RUN apk add jq
COPY --chown=0:0 image/ /
CMD ["/bin/contour-auto-include.sh", "update", "--interval=10"]
