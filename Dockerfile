# syntax=docker/dockerfile:1

#Pull the latest golang base image and build from image from it.
FROM golang:alpine AS buildfirstimage

## install git and update certificates
RUN apk add --no-cache git && update-ca-certificates

# Create appuser
ENV USER=Produser
ENV UID=10001

# See https://stackoverflow.com/a/55757473/12429735
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"

# Working directory to run commands.
WORKDIR /app

# Copy the go.mod and main.go file to the current working directory specified above (app)
# We are using the copy copy instead of git clone.
# This is to avoid any issues when deploying to production.
COPY go.mod .

# This downloads all of the dependanies needed to run the web server

RUN go mod download

COPY *.go ./

#Build binary
RUN CGO_ENABLED=0 GOOS=linux go build -o /docker-go-keyword



#Using Multi-stage-build to build compressed image size.
#Final image is built from final artifact built above
FROM gcr.io/distroless/base AS finalimage

#Name of the operator maininting the dockerfile.
LABEL maintainer="Wale <georgeeolawale@gmail.com>"

WORKDIR /

#copy users to the finalimage from the firstimage
COPY --from=buildfirstimage /etc/passwd /etc/passwd
COPY --from=buildfirstimage /etc/group /etc/group

#Binary contains only what we need to run the webserver
#copy binary created from first step
COPY --from=buildfirstimage --chown=Produser:Produser  /docker-go-keyword /docker-go-keyword

ENV PORT 3030

EXPOSE 3030

USER Produser:Produser

ENTRYPOINT ["/docker-go-keyword"]
