module Scanner
    exposing
        ( Config
        , Name
        , Error
        , scanFile
        , scanBuffer
        , scanString
        )

{-| Clamav Scan Api.

# Scanner
@docs Config, Name, Error, scanFile, scanBuffer, scanString
-}

import Native.Scanner
import Task
import Utils.Ops exposing (..)
import Node.Encoding as Encoding exposing (..)
import Node.Buffer as Buffer exposing (..)
import Node.FileSystem as NodeFileSystem exposing (..)
import Node.Error as NodeError exposing (..)


{-| Scan name
-}
type alias Name =
    String


{-| Scan error
-}
type alias Error =
    { message : String
    , virusName : Maybe String
    }


{-| Config
-}
type alias Config =
    { clamavHost : String
    , clamavPort : Int
    , debug : Bool
    }


type alias ScannerComplete msg =
    Result ( Name, Error ) Name -> msg


{-| Scan File for viruses.

```
type Msg =
    ScannerComplete (Result ( Name, Error ) Name)

scanFile config "testfile.txt" ScannerComplete true
```
-}
scanFile : Config -> String -> ScannerComplete msg -> Cmd msg
scanFile config filename tagger =
    log config.debug "Reading file" filename
        |> NodeFileSystem.readFile
        |> Task.mapError (\error -> ( filename, { message = NodeError.message error, virusName = Nothing } ))
        |> Task.andThen (\buffer -> (log config.debug "scanBuffer" filename) |> (\_ -> Native.Scanner.scan config filename buffer))
        |> Task.attempt tagger


{-| Scan Buffer for viruses.

```
type Msg =
    ScannerComplete (Result ( Name, Error ) Name)

scanBuffer config "testBuffer" buffer ScannerComplete false
```
-}
scanBuffer : Config -> String -> Buffer -> ScannerComplete msg -> Cmd msg
scanBuffer config targetName targetBuffer tagger =
    log config.debug "scanBuffer" targetName
        |> (\_ -> internalScanBuffer config targetName targetBuffer tagger)


{-| Scan String for viruses.

```
type Msg =
    ScannerComplete (Result ( Name, Error ) Name)

scanString config "testString" "testingString" Encoding.Utf8 ScannerComplete true
```
-}
scanString : Config -> String -> String -> Encoding -> ScannerComplete msg -> Cmd msg
scanString config targetName targetString encoding tagger =
    String.length targetString
        |> (\stringLength ->
                log config.debug
                    "scanString"
                    { name = targetName
                    , string = (String.left 80 targetString)
                    , stringEncoding = (Encoding.toString encoding)
                    , partialStringDisplay = (stringLength > 80) ? ( True, False )
                    }
           )
        |> (\_ ->
                fromString encoding targetString
                    |??> (\buffer -> internalScanBuffer config targetName buffer tagger)
                    ??= (\error -> Task.fail ( targetName, { message = NodeError.message error, virusName = Nothing } ) |> Task.attempt tagger)
           )


internalScanBuffer : Config -> String -> Buffer -> ScannerComplete msg -> Cmd msg
internalScanBuffer config targetName targetBuffer tagger =
    Native.Scanner.scan config targetName targetBuffer
        |> Task.attempt tagger


log : Bool -> String -> a -> a
log debug title value =
    debug
        ?! ( \_ -> Debug.log ("Scanner -- " ++ title) value, \_ -> value )
