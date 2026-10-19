# The web build behind nginx: serves the app, the face picker at /faces.html, the ovos-gui cache under /res/, host
# files under /res-abs/, and proxies the two OVOS websockets so the sidecar's port is the only one a remote browser
# needs (docs/SCOPE.md).
# Build from the repository root: docker build -f sidecar/Dockerfile .
# The web build is the same on every architecture, so the Flutter stage runs on the build platform and only the nginx
# stage is per target: a multi-arch build needs no emulation.
FROM --platform=$BUILDPLATFORM debian:bookworm-slim AS build
ARG FLUTTER_VERSION=3.47.4
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter
ENV PATH=/opt/flutter/bin:$PATH
RUN flutter config --no-analytics && flutter precache --web
WORKDIR /src
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release

FROM nginx:1.27-alpine
ENV OVOS_HOST=host.docker.internal
ENV OVOS_BUS_PORT=8181
ENV OVOS_GUI_PORT=18181
COPY sidecar/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /src/build/web /usr/share/nginx/html
COPY docs/face-palettes.html /usr/share/nginx/html/faces.html
EXPOSE 8080
