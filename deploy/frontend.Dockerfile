# MamaSafe React frontend (Vite build served by nginx:alpine)
# Build: docker build -f deploy/frontend.Dockerfile -t mamasafe-frontend .
# Context must be frontend/
#
# VITE_API_URL is passed as a build arg. Leave empty for same-origin API
# routing through Nginx (recommended); or set to https://api.yourdomain.com.
FROM node:20-alpine AS build
WORKDIR /app

ARG VITE_API_URL=
ARG VITE_APK_URL=
ARG VITE_APK_VERSION=
ARG VITE_APK_CHECKSUM=
ARG VITE_APK_CHANGELOG=

ENV VITE_API_URL=$VITE_API_URL \
    VITE_APK_URL=$VITE_APK_URL \
    VITE_APK_VERSION=$VITE_APK_VERSION \
    VITE_APK_CHECKSUM=$VITE_APK_CHECKSUM \
    VITE_APK_CHANGELOG=$VITE_APK_CHANGELOG

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
# Remove any dev .env so production build args are the only source of truth
RUN rm -f .env .env.local
RUN npm run build

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
