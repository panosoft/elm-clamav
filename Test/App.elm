port module App exposing (..)

-- Needed otherwise Json.Decode is not included in compiled js

import Json.Decode
import Scanner exposing (..)
import Node.Encoding as Encoding exposing (..)
import Node.Buffer as Buffer exposing (..)
import Node.Error as NodeError exposing (..)
import Utils.Ops exposing (..)


port exitApp : Float -> Cmd msg


port externalStop : (() -> msg) -> Sub msg


type alias Flags =
    { clamavHost : String
    , clamavPort : String
    }


type alias Model =
    {}


model : Model
model =
    {}


type Msg
    = Exit ()
    | ScannerComplete (Result String String)


init : Flags -> ( Model, Cmd Msg )
init flags =
    String.toInt flags.clamavPort
        |??>
            (\clamavPort ->
                Scanner.config flags.clamavHost clamavPort
                    |> (\config ->
                            model
                                ! [ Scanner.scanString config "scanString TEST" "hi there" Utf8 ScannerComplete
                                  , Scanner.scanString config "scanString BASE64 TEST" (encodeString Base64 "hi there base64") Base64 ScannerComplete
                                  ]
                       )
            )
        ??= (\error -> Debug.crash ("Invalid clamavPort: " ++ error))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Exit _ ->
            model ! [ exitApp 1 ]

        ScannerComplete (Err error) ->
            let
                l =
                    Debug.log "ScannerComplete Error" error
            in
                model ! []

        ScannerComplete (Ok message) ->
            let
                l =
                    Debug.log "ScannerComplete" message
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


encodeString : Encoding -> String -> String
encodeString encoding str =
    (Buffer.fromString Encoding.Utf8 str
        |> Result.andThen (Buffer.toString encoding)
        |> Result.mapError (\error -> NodeError.message <| error)
    )
        ??= (\error -> Debug.crash ("Encode error: " ++ error))
