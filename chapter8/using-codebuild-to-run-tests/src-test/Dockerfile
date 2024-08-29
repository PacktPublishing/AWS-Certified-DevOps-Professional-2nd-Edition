# syntax=docker/dockerfile:1
FROM golang:1.23 AS build

# Set destination for COPY
WORKDIR /app

# Download Go modules
COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o hello

FROM alpine:3.20.2

COPY --from=build /app/hello /hello

EXPOSE 8080

# Run
CMD ["/hello"]
