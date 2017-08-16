# ClamAV API for Elm

> An Elm library that provides access to the ClamAV virus scanning API.

> This library is built on top of the node `ClamAV` library, [clamav.js](https://github.com/yongtang/clamav.js), which uses [ClamAV](https://www.clamav.net/) to provide its virus scanning functionality.

## Install

### Elm

Since the Elm Package Manager doesn't allow for Native code and this uses Native code, you have to install it directly from GitHub, e.g. via [elm-github-install](https://github.com/gdotdesign/elm-github-install) or some equivalent mechanism.

### ClamAV package

[ClamAV](https://www.clamav.net/) daemon must be installed at the `clamavHost` and `clamavPort` (see `ClamAV Config` below).

### Node modules

You'll also need to install the dependent node modules at the root of your Application Directory. See the example `package.json` for a list of the dependencies.

The installation can be done via `npm install` command.

### Test program

Purpose is to test the `clamav.js` virus scanning API that this library supports . Use `aBuild.sh` or `build.sh` to build it and run it with `node main.js` command (see `main.js` for command line parameters).

## API

### ClamAV Config used in all virus scanning commands

__Config__

```elm
type alias Config =
    { clamavHost : String
    , clamavPort : Int
    , debug : Bool
    }
```

* `clamavHost` is the host name where the `ClamAV` daemon is running.
* `clamavPort` is the port where the `ClamAV` daemon is running.
* `debug` is True if debug logging is desired, False otherwise


__Usage__

```elm
config : Config
config =
    { clamavHost = "clamavHost"
    , clamavPort = 3310
    , debug = False
    }
```

### Commands

> Scan File for virus

Scan file for a virus using the ClamAV daemon.

```elm
scanFile : Config -> String -> ScannerCompleteTagger msg -> Cmd msg
scanFile config filename tagger =
```
__Usage__

```elm
scanFile config filename ScannerComplete
```
* `ScannerComplete` is your application's message to handle the different result scenarios
* `config` has fields used to configure the request
* `filename` is the name of the file to scan for a virus

> Scan Buffer for virus

Scan a Buffer for a virus using the ClamAV daemon. This command uses `Buffer` defined in [elm-node/core](https://github.com/elm-node/core).

```elm
scanBuffer : Config -> String -> Buffer -> ScannerCompleteTagger msg -> Cmd msg
scanBuffer config targetName targetBuffer tagger =
```
__Usage__

```elm
scanBuffer config targetName targetBuffer ScannerComplete
```
* `ScannerComplete` is your application's message to handle the different result scenarios
* `config` has fields used to configure the request
* `targetName` is the name used to identify this scan in the `ScannerComplete` msg
* `targetBuffer` is the buffer to scan for a virus

> Scan String for virus

Scan a String for a virus using the ClamAV daemon. This command uses `Encoding` defined in [elm-node/core](https://github.com/elm-node/core).

```elm
scanString : Config -> String -> String -> Encoding -> ScannerCompleteTagger msg -> Cmd msg
scanString config targetName targetString encoding tagger =
```
__Usage__

```elm
scanString config targetName targetString encoding ScannerComplete =
```
* `ScannerComplete` is your application's message to handle the different result scenarios
* `config` has fields used to configure the request
* `targetName` is the name used to identify this scan in the `ScannerComplete` msg
* `targetString` is the string to scan for a virus
* `encoding` is the encoding of the targetString (see `Encoding` defined in [elm-node/core](https://github.com/elm-node/core))


### Subscriptions

> There are no subscriptions.

### Types

#### Name

Scan Name.  This is `filename` for the `ScanFile` operation, and `targetName` for `ScanBuffer` and `ScanString` operations.

``` elm
type alias Name =
    String
```

#### Error

Error information from a scan.

``` elm
type alias Error =
    { message : String
    , virusName : Maybe String
    }
```
* `message` is the error message returned from the scan
* `virusName` if the scan error was due to a virus being found then this is the name of the virus, otherwise `Nothing`

#### ScannerCompleteTagger

Returns an Elm Result indicating a successful call to one of the `Scan` operations or an error consisting of `(Name, Error)`.

```elm
type alias ScannerComplete msg =
    Result ( Name, Error ) Name -> msg
```

__Usage__

```elm
ScannerComplete (Ok name) ->
    let
        l =
            Debug.log "ScannerComplete" name
    in
    model ! []

ScannerComplete (Err (name, error)) ->
    let
        l =
            Debug.log "ScannerComplete Error" (name, error)
    in
        model ! []
```
