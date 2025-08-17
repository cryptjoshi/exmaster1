FROM node:18-alpine AS frontend-builder

RUN npm install -g pnpm

WORKDIR /app/static

# copy แค่ไฟล์ package ก่อน (ใช้ cache ได้)
COPY static/package.json static/pnpm-lock.yaml* ./

RUN pnpm install --no-frozen-lockfile

# copy project ทั้งหมดเข้ามา
COPY static/ ./

RUN pnpm run build


# Go application
FROM golang:1.21-alpine AS go-builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod tidy

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage
FROM alpine:3.19

# RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.edge.kernel.org/g' /etc/apk/repositories \
#  && apk add --no-cache ca-certificates tzdata

WORKDIR /root/

# Copy the Go binary
COPY --from=go-builder /app/main .

# Copy the built frontend
COPY --from=frontend-builder /app/static/dist ./static/dist

# Expose port
EXPOSE 8088

# Command to run
CMD ["./main"]
