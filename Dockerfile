FROM gcr.io/cloud-builders/gcloud-slim as gcloud
FROM openjdk:8-jre
ARG NAME
ARG VENDOR
ARG SUMMARY
ARG DESC
ARG LASTCOMMIT
ARG BUILDTIME
ARG VERSION
COPY ./docker-entrypoint.sh /blackduck-cloudbuild-scanner/docker-entrypoint.sh
COPY --from=gcloud /builder/* /google-cloud-sdk/.
RUN \
    apt-get clean && \
    apt-get -y update && \
    apt-get --fix-broken -y install && \
    apt-get -y install curl jq python2.7 gnupg2
ENV PATH $PATH:/google-cloud-sdk/bin
CMD [ "-hv" ]
ENTRYPOINT [ "/blackduck-cloudbuild-scanner/docker-entrypoint.sh" ]