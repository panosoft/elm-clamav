port module App exposing (..)

-- Needed otherwise Json.Decode is not included in compiled js

import Json.Decode
import Task exposing (Task)
import Scanner exposing (..)
import Node.Encoding as Encoding exposing (..)
import Node.Buffer as Buffer exposing (..)
import Node.FileSystem as NodeFileSystem exposing (..)
import Node.Error as NodeError exposing (..)
import Utils.Ops exposing (..)


port exitApp : Float -> Cmd msg


port externalStop : (() -> msg) -> Sub msg


type alias Config =
    { clamavHost : String
    , clamavPort : Int
    , testfile : String
    , debug : Bool
    }


type alias Flags =
    { config : Config
    }


type alias Model =
    { scannerConfig : Scanner.Config }


initModel : Config -> Model
initModel config =
    { scannerConfig = Scanner.Config config.clamavHost config.clamavPort }


type Msg
    = Exit ()
    | ReadFileComplete String Bool (Result String Buffer)
    | ScannerComplete (Result ( String, String ) String)


init : Flags -> ( Model, Cmd Msg )
init flags =
    initModel flags.config
        |> (\model ->
                buildTestCmd model.scannerConfig flags.config.testfile flags.config.debug
                    |> (\cmds -> model ! cmds)
           )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Exit _ ->
            model ! [ exitApp 1 ]

        ReadFileComplete filename debug (Err error) ->
            let
                l =
                    Debug.log "ReadFileComplete Error" error
            in
                model ! []

        ReadFileComplete filename debug (Ok buffer) ->
            let
                l =
                    Debug.log "ReadFileComplete" filename
            in
                model ! [ Scanner.scanBuffer model.scannerConfig (filename ++ " Buffer TEST") buffer ScannerComplete debug ]

        ScannerComplete (Err error) ->
            let
                l =
                    Debug.log "ScannerComplete Error" error
            in
                model ! []

        ScannerComplete (Ok name) ->
            let
                l =
                    Debug.log "ScannerComplete" name
            in
                model ! []


main : Program Flags Model Msg
main =
    Platform.programWithFlags
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    externalStop Exit


buildTestCmd : Scanner.Config -> String -> Bool -> List (Cmd Msg)
buildTestCmd config testfile debug =
    [ Scanner.scanFile config testfile ScannerComplete debug
    , readFileCmd testfile debug
    , Scanner.scanString config "scanString BASE64 TEST" (encodeString Base64 "hi there base64") Base64 ScannerComplete debug
    , Scanner.scanString config "scanString TEST" "hi there" Utf8 ScannerComplete debug
    ]


readFileCmd : String -> Bool -> Cmd Msg
readFileCmd filename debug =
    NodeFileSystem.readFile filename
        |> Task.mapError (\error -> NodeError.message error)
        |> Task.attempt (ReadFileComplete filename debug)


encodeString : Encoding -> String -> String
encodeString encoding str =
    (Buffer.fromString Encoding.Utf8 str
        |> Result.andThen (Buffer.toString encoding)
        |> Result.mapError NodeError.message
    )
        ??= (\error -> Debug.crash ("Encode error: " ++ error))
