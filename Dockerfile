FROM --platform=linux/amd64 golang:1.21 AS builder
WORKDIR /app
ADD main.go main.go
COPY go.mod .
COPY go.sum .
RUN CGO_ENABLED=0 GOOS=linux go build -o main main.go

FROM --platform=linux/amd64 alpine:latest AS services
WORKDIR /app

COPY --from=builder /app/main .