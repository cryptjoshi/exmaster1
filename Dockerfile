FROM node:18-alpine AS frontend-builder

RUN npm install -g pnpm

WORKDIR /app/static

# copy แค่ไฟล์ package ก่อน (ใช้ cache ได้)
COPY static/package.json static/pnpm-lock.yaml* ./

RUN pnpm install --no-frozen-lockfile

# copy project ทั้งหมดเข้ามา
COPY static/ ./

RUN pnpm run build

FROM golang:1.23.0-alpine3.20 as go-builder
RUN apk add --update git
RUN apk add --update curl

# ติดตั้ง tzdata เพื่อให้สามารถตั้งค่า Time Zone ได้
RUN apk add --no-cache tzdata

# คัดลอกไฟล์โซนเวลาที่ต้องการ (เช่น Asia/Bangkok)
ENV TZ=Asia/Bangkok

WORKDIR /app

#RUN curl -fLo install.sh https://raw.githubusercontent.com/cosmtrek/air/master/install.sh \
#    && chmod +x install.sh && sh install.sh && cp ./bin/air /bin/air
 
RUN go install github.com/air-verse/air@latest

COPY go.mod go.sum ./


RUN go mod download

#CMD ["air"]
#EXPOSE 3001

CMD ["air", "-c", ".air.toml"]
# # Go application
# FROM golang:1.21-alpine AS go-builder

# # ตั้งค่า proxy และ DNS helper
# #ENV GOPROXY=https://goproxy.io,direct
# #ENV GOSUMDB=off  
# #ใช้เฉพาะในกรณีเร่งด่วน (ไม่แนะนำใน production)

# # ติดตั้งเครื่องมือพื้นฐาน
# RUN apk add --no-cache curl ca-certificates

# # ตรวจสอบการเชื่อมต่อ (debug)
# # RUN curl -s https://proxy.golang.org | head -n 5

# WORKDIR /app
# COPY go.mod go.sum ./
# RUN go mod tidy
# RUN go mod vendor

# COPY . .
# RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .
# #RUN CGO_ENABLED=0 GOOS=linux go build -v -o main ./


# # Final stage
# FROM alpine:3.19

# # RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.edge.kernel.org/g' /etc/apk/repositories \
# #  && apk add --no-cache ca-certificates tzdata

# WORKDIR /root/

# # Copy the Go binary
# COPY --from=go-builder /app/main .

# # Copy the built frontend
# COPY --from=frontend-builder /app/static/dist ./static/dist

# # Expose port
# EXPOSE 8088

# # Command to run
# CMD ["./main"]
