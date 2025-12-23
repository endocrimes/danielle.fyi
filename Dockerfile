FROM --platform=$BUILDPLATFORM ghcr.io/gohugoio/hugo AS builder

COPY . /project

RUN hugo

FROM --platform=$TARGETPLATFORM pierrezemb/gostatic

COPY --from=builder /project/public /srv/http
