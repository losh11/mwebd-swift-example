# mweb-swift-example

This is an example iOS Swift app demonstrating the integration of MWEBD.

We have provided instructions below on how to add MWEBD into your own wallet.

## MWEBD Swift Integration

Instructions for adding MWEBD into your own Swift iOS/macOS app.

### Build & Link MWEBD
Requirement: install [Go v1.24+](https://go.dev/doc/install)

```bash
# Setup gomobile
$ go install golang.org/x/mobile/cmd/gomobile@latest
$ gomobile init

# build Mwebd.framework
$ go tool gomobile bind -target=ios github.com/ltcmweb/mwebd
```

1. Copy over the generated `Mwebd.framework` into your Xcode Project.
2. Under `Targets > App Name > General > Frameworks, Libraries, and Embedded Content` you must Embed & Sign the `Mwebd.framework` library.
3. Add a new library by clicking on the + button in `Frameworks, Libraries, and Embedded Content`. In the popup, search for `libresolv.9.tbd`. Add it!
4. Under `Targets > App Name > Build Phases > Link Binary with Libraries`, confirm `libresolv.9.tbd` is linked. If not, press the + button and link it again.

You app should now build successfully with the MWEBD library!

### Client & Server

The MWEBD library only exposes certain apis as a callable function. To `getStatus()`, `createTransaction()` etc. you must first connect to MWEBD over grpc and make these calls. In this example app, we have created a `MwebClient` wrapper for these calls. We suggest you do something similar.

MWEBD provides bindings for the language of your choosing, which can be generated from protobufs. For an iOS Swift project, here's how to generate bindings.

First install the required tools (protoc, protoc-gen-swift and protoc-gen-grpc-swift):
```bash
# protoc
$ brew install protobuf

# protoc-gen-swift
$ git clone https://github.com/apple/swift-protobuf.git
$ cd swift-protobuf
$ swift build -c release
$ sudo cp .build/release/protoc-gen-swift /usr/local/bin/

# protoc-gen-grpc-swift
$ brew install protoc-gen-grpc-swift
```

Generate the bindings:
```bash
# locate the .proto file in the mwebd repo, in the proto folder
$ cd proto
$ protoc --swift_out=. --grpc-swift_out=. --plugin=protoc-gen-swift=$(which protoc-gen-swift) --plugin=protoc-gen-grpc-swift=$(which protoc-gen-grpc-swift) ./mwebd.proto
```

Copy the generated .swift bindings into your Xcode Project.

Now installed these dependencies through Swift Package Manager:
- swift-protobuf
- grpc-swift (https://github.com/grpc/grpc-swift.git)
- grpc-swift-protobuf (https://github.com/grpc/grpc-swift-protobuf.git)

You app should now build without errors.

#### Communicating with MWEBD
Please see the example app on how to start grpc server. After you are able to start the server without errors, we reccomend writing a client wrapper for Mwebd. An example client wrapper has also been provided: `MwebClient.swift`.

Please see our example app for more details.
