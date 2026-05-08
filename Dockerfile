# Triptastic — production image
# Builds the React frontend and runs the Node.js API on the same port.
FROM node:20-alpine AS frontend-build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS server-deps
WORKDIR /app
COPY server/package*.json ./
RUN npm ci --omit=dev

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
RUN apk add --no-cache tini postgresql-client
COPY --from=server-deps /app/node_modules ./node_modules
COPY server ./
COPY --from=frontend-build /app/dist ./dist
RUN mkdir -p /app/uploads
EXPOSE 3045
ENTRYPOINT ["/sbin/tini","--"]
CMD ["node","index.js"]
