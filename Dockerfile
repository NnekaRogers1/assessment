FROM golang:1.25 AS build

WORKDIR /go/src/tasky
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /go/src/tasky/tasky

RUN echo "Nneka Rodgers" > /go/src/tasky/wizexercise.txt

FROM alpine:3.23.3 as release

WORKDIR /app
COPY --from=build /go/src/tasky/tasky .
COPY --from=build /go/src/tasky/assets ./assets
COPY --from=build /go/src/tasky/wizexercise.txt .

EXPOSE 8080
ENTRYPOINT ["/app/tasky"]