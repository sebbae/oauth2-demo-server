# OAuth2 demo server

A simple server project with OAuth2 resource protection.

The project uses Github as example OAuth provider

## Usage

1. Run `dep ensure` to fetch dependencies
1. Register application at Github
1. Add `ClientID` and `ClientSecret` in main.go
1. Choose a new secure session cookie store key in main.go
1. Build using `go build`
1. Start service
