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
    }


type alias Flags =
    { testfile : String
    , config : Config
    , debug : String
    }


type alias Model =
    { scannerConfig : Scanner.Config
    , numberOfTests : Int
    , testsComplete : Int
    }


initModel : Config -> String -> Bool -> ( Model, Cmd Msg )
initModel config testfile debug =
    Scanner.Config config.clamavHost config.clamavPort
        |> (\scannerConfig ->
                buildTestCmd scannerConfig testfile debug
                    |> (\cmds -> ({ scannerConfig = scannerConfig, numberOfTests = List.length cmds, testsComplete = 0 } ! cmds))
           )


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        l =
            Debug.log "flags" flags
    in
        (flags.debug == "--debug")
            ?! ( always True
               , (\_ -> (flags.debug == "") ?! ( always False, (\_ -> Debug.crash ("optional debug parameter invalid: " ++ (Basics.toString flags.debug) ++ " . must be --debug if specified")) ))
               )
            |> initModel flags.config flags.testfile


type Msg
    = Exit ()
    | ReadFileComplete String Bool (Result String Buffer)
    | ScannerComplete (Result ( String, String ) String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        processTestsComplete testsComplete =
            (testsComplete >= model.numberOfTests)
                ? ( Task.perform Exit <| Task.succeed ()
                  , Cmd.none
                  )
                |> (\cmd -> ({ model | testsComplete = testsComplete } ! [ cmd ]))
    in
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
                    model ! [ Scanner.scanBuffer model.scannerConfig ("scanBuffer TEST (buffer read from " ++ filename ++ ")") buffer ScannerComplete debug ]

            ScannerComplete (Err error) ->
                let
                    l =
                        Debug.log "ScannerComplete Error" error
                in
                    processTestsComplete (model.testsComplete + 1)

            ScannerComplete (Ok name) ->
                let
                    l =
                        Debug.log "ScannerComplete" name
                in
                    processTestsComplete (model.testsComplete + 1)


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
    , Scanner.scanString config "scanString BASE64 TEST" (encodeString Base64 "This is an encoded base64 test string!") Base64 ScannerComplete debug
    , Scanner.scanString config "scanString TEST" "This is a test string!" Utf8 ScannerComplete debug
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
