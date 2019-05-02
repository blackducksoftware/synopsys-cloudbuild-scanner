FROM gcr.io/cloud-builders/gcloud-slim as gcloud
FROM openjdk:8-jre
ARG NAME
ARG VENDOR
ARG SUMMARY
ARG DESC
ARG LASTCOMMIT
ARG BUILDTIME
ARG VERSION
COPY ./docker-entrypoint.sh /synopsys/docker-entrypoint.sh
COPY --from=gcloud /builder/* /google-cloud-sdk/.
ENV DETECT_JAR_DOWNLOAD_DIR=/synopsys/detect
RUN \
    apt-get clean && \
    apt-get -y update && \
    apt-get --fix-broken -y install && \
    apt-get -y install curl jq python2.7 gnupg2 && \
    \
    mkdir -p "${DETECT_JAR_DOWNLOAD_DIR}" && \
    if [ $(curl -s -L -w '%{http_code}' https://detect.synopsys.com/detect.sh -o "${DETECT_JAR_DOWNLOAD_DIR}"/detect_local.sh) != "200" ]; then exit 1; else chmod 755 "${DETECT_JAR_DOWNLOAD_DIR}"/detect_local.sh; fi && \
    DETECT_DOWNLOAD_ONLY=1 "${DETECT_JAR_DOWNLOAD_DIR}"/detect_local.sh && \
    rm "${DETECT_JAR_DOWNLOAD_DIR}"/detect_local.sh
ENV PATH $PATH:/google-cloud-sdk/bin
CMD [ "-hv" ]
ENTRYPOINT [ "/synopsys/docker-entrypoint.sh" ]