module Scanner
    exposing
        ( config
        , scanBuffer
        , scanString
        )

{-| Clamav Scan Api.

# Scanner
@docs config, scanBuffer, scanString
-}

import Native.Scanner
import Task
import Utils.Ops exposing (..)
import Node.Encoding as Encoding exposing (..)
import Node.Buffer as Buffer exposing (..)
import Node.Error as NodeError exposing (..)


type alias Config =
    { clamavHost : String
    , clamavPort : Int
    }


{-| Create a configuration .

```
config = Scanner.config
    "Clamav Host"
    "Clamav Port"

```
-}
config : String -> Int -> Config
config =
    Config


{-| Scan Buffer for viruses.

```
type Msg =
    ScanComplete (Result String String)

scanBuffer config "<name> <node buffer> ScanComplete
```
-}
scanBuffer : Config -> String -> Buffer -> (Result String String -> msg) -> Cmd msg
scanBuffer config name buffer tagger =
    Native.Scanner.scan config name buffer
        |> Task.attempt tagger


{-| Scan String for viruses.

```
type Msg =
    ScanComplete (Result String String)

scanString config "<name> <string to scan> <string encoding> ScanComplete
```
-}
scanString : Config -> String -> String -> Encoding -> (Result String String -> msg) -> Cmd msg
scanString config name targetString encoding tagger =
    let
        l =
            Debug.log "scanString" ("--> " ++ name ++ " --> " ++ targetString ++ " --> " ++ (Encoding.toString encoding))
    in
        fromString encoding targetString
            |??> (\buffer -> scanBuffer config name buffer tagger)
            ??= (\error -> Task.fail (NodeError.message error) |> Task.attempt tagger)
