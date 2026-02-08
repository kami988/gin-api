//go:build tools

package tools

import (
	_ "connectrpc.com/connect/cmd/protoc-gen-connect-go"
	_ "github.com/air-verse/air"
	_ "github.com/golang/mock/mockgen"
	_ "github.com/golangci/golangci-lint/v2/cmd/golangci-lint"
	_ "github.com/pressly/goose/v3"
	_ "google.golang.org/protobuf/cmd/protoc-gen-go"
	_ "github.com/bufbuild/buf/cmd/buf"
	_ "github.com/fullstorydev/grpcurl/cmd/grpcurl"
)
