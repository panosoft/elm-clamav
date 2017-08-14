# ClamAV API for Elm

> An Elm library that provides access to the ClamAV virus scanning API.

> This library is built on top of the node `ClamAV` library, [clamav.js](https://github.com/yongtang/clamav.js), which uses [ClamAV](https://www.clamav.net/) to provide its virus scanning functionality.

## Install

### Elm

Since the Elm Package Manager doesn't allow for Native code and this uses Native code, you have to install it directly from GitHub, e.g. via [elm-github-install](https://github.com/gdotdesign/elm-github-install) or some equivalent mechanism.

### ClamAV package

[ClamAV](https://www.clamav.net/) must be installed at the `clamavHost` and `clamavPort` (see `ClamAV Config` below).

### Node modules

You'll also need to install the dependent node modules at the root of your Application Directory. See the example `package.json` for a list of the dependencies.

The installation can be done via `npm install` command.

### Test program

Purpose is to test the clamav.js virus scanning API that this library supports . Use `aBuild.sh` or `build.sh` to build it and run it with `node main` command.

## API

### ClamAV Config used in all virus scanning commands

__Config__

```elm
type alias Config =
    { clamavHost : String
    , clamavPort : Int
    }
```

* `clamavHost` is the host name where the `ClamAV` daemon is running.
* `clamavPort` is the port where the `ClamAV` daemon is running.


__Usage__

```elm
config : Config
config =
    { clamavHost = "<host name of ClamAV daemon>"
    , clamavPort = "<port of ClamAV daemon>"
    }
```

### Commands

> Scan File for virus

Scan file for a virus using the ClamAV daemon.

```elm
scanFile : Config -> String -> ScannerCompleteTagger msg -> Bool -> Cmd msg
scanFile config filename tagger debug =
```
__Usage__

```elm
scanFile config filename ScannerComplete debug
```
* `ScannerComplete` is your application's message to handle the different result scenarios
* `config` has fields used to configure the request
* `filename` is the name of the file to scan for a virus
* `debug` is True if debug logging is desired, False otherwise

> Scan Buffer for virus

Scan a Buffer for a virus using the ClamAV daemon. This command uses `Buffer` defined in [elm-node/core](https://github.com/elm-node/core).

```elm
scanBuffer : Config -> String -> Buffer -> ScannerCompleteTagger msg -> Bool -> Cmd msg
scanBuffer config targetName targetBuffer tagger debug =
```
__Usage__

```elm
scanBuffer config targetName targetBuffer ScannerComplete debug
```
* `ScannerComplete` is your application's message to handle the different result scenarios
* `config` has fields used to configure the request
* `targetName` is the name used to identify this scan
* `targetBuffer` is the buffer to scan for a virus
* `debug` is True if debug logging is desired, False otherwise

> Scan String for virus

Scan a String for a virus using the ClamAV daemon. This command uses `Encoding` defined in [elm-node/core](https://github.com/elm-node/core).

```elm
scanString : Config -> String -> String -> Encoding -> ScannerCompleteTagger msg -> Bool -> Cmd msg
scanString config targetName targetString encoding tagger debug =
```
__Usage__

```elm
scanString config targetName targetString encoding ScannerComplete debug =
```
* `ScannerComplete` is your application's message to handle the different result scenarios
* `config` has fields used to configure the request
* `targetName` is the name used to identify this scan
* `targetString` is the string to scan for a virus
* `encoding` is the encoding of the targetString (see `Encoding` defined in [elm-node/core](https://github.com/elm-node/core))
* `debug` is True if debug logging is desired, False otherwise


### Subscriptions

> There are no subscriptions.

### Types

#### ScannerCompleteTagger

Returns an Elm Result indicating a successful call to one of the `scan` operations or an error.  If an error is returned due to a virus found during the scan, the virus is identified in the error message.

```elm
type alias ObjectExistsTagger msg =
    ( Result String String ) -> msg
```

__Usage__

```elm
ScannerComplete (Ok message) ->
    let
        l =
            Debug.log "ScannerComplete" message
    in
    model ! []

ScannerComplete (Err error) ->
    let
        l =
            Debug.log "ScannerComplete Error" error
    in
        model ! []
```
