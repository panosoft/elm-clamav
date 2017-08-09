module Scanner
    exposing
        ( Config
        , scanFile
        , scanBuffer
        , scanString
        )

{-| Clamav Scan Api.

# Scanner
@docs Config, scanFile, scanBuffer, scanString
-}

import Native.Scanner
import Task
import Utils.Ops exposing (..)
import Node.Encoding as Encoding exposing (..)
import Node.Buffer as Buffer exposing (..)
import Node.FileSystem as NodeFileSystem exposing (..)
import Node.Error as NodeError exposing (..)


{-| Config
-}
type alias Config =
    { clamavHost : String
    , clamavPort : Int
    }


type alias ScannerComplete msg =
    Result ( String, String ) String -> msg


{-| Scan File for viruses.

```
type Msg =
    ScanComplete (Result String String)

scanFile config "testfile.txt" ScanComplete true
```
-}
scanFile : Config -> String -> ScannerComplete msg -> Bool -> Cmd msg
scanFile config filename tagger debug =
    debug
        ?! ( (\_ -> Debug.log "Scanner -- Reading file" filename), (\_ -> filename) )
        |> NodeFileSystem.readFile
        |> Task.mapError (\error -> ( filename, NodeError.message error ))
        |> Task.andThen (\buffer -> Native.Scanner.scan config filename buffer debug)
        |> Task.attempt tagger


{-| Scan Buffer for viruses.

```
type Msg =
    ScanComplete (Result String String)

scanBuffer config "testBuffer" buffer ScanComplete false
```
-}
scanBuffer : Config -> String -> Buffer -> ScannerComplete msg -> Bool -> Cmd msg
scanBuffer config targetName targetBuffer tagger debug =
    Native.Scanner.scan config targetName targetBuffer debug
        |> Task.attempt tagger


{-| Scan String for viruses.

```
type Msg =
    ScanComplete (Result String String)

scanString config "testString" "testingString" Encoding.Utf8 ScanComplete true
```
-}
scanString : Config -> String -> String -> Encoding -> ScannerComplete msg -> Bool -> Cmd msg
scanString config targetName targetString encoding tagger debug =
    let
        l =
            debug
                ?! ( (\_ ->
                        (String.length targetString)
                            |> (\stringLength ->
                                    (Debug.log "Scanner -- scanString" <| Basics.toString { name = targetName, string = (String.left 80 targetString), stringEncoding = (Encoding.toString encoding), partialStringDisplay = (stringLength > 80) ? ( True, False ) })
                               )
                     )
                   , (\_ -> "")
                   )
    in
        fromString encoding targetString
            |??> (\buffer -> scanBuffer config targetName buffer tagger debug)
            ??= (\error -> Task.fail ( targetName, NodeError.message error ) |> Task.attempt tagger)
