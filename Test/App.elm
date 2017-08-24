port module App exposing (..)

--TODO Bug in 0.18 Elm compiler.  import is needed otherwise Json.Decode is not included in compiled js

import Json.Decode
import Task exposing (Task)
import Scanner exposing (..)
import Node.Encoding as Encoding exposing (..)
import Node.Buffer as Buffer exposing (..)
import Node.FileSystem as NodeFileSystem exposing (..)
import Node.Error as NodeError exposing (..)
import Utils.Ops exposing (..)
import DebugF exposing (..)


port exitApp : Float -> Cmd msg


port externalStop : (() -> msg) -> Sub msg


type alias Config =
    { clamavHost : String
    , clamavPort : Int
    }


type alias Flags =
    { targetFilename : String
    , config : Config
    , debug : String
    }


type alias Model =
    { scannerConfig : Scanner.Config
    , numberOfTests : Int
    , testsComplete : Int
    , errorOccurred : Bool
    }


initModel : Config -> String -> Bool -> ( Model, Cmd Msg )
initModel config testfile debug =
    Scanner.Config config.clamavHost config.clamavPort debug
        |> (\scannerConfig -> ({ scannerConfig = scannerConfig, numberOfTests = 0, testsComplete = 0, errorOccurred = False } ! [ readFileCmd testfile ]))


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        l =
            DebugF.log "flags" flags
    in
        (flags.debug == "--debug")
            ?! ( always True
               , (\_ ->
                    (flags.debug == "")
                        ?! ( always False
                           , (\_ -> Debug.crash ("optional debug parameter invalid: " ++ (Basics.toString flags.debug) ++ " . must be --debug if specified.\n\n" ++ usage))
                           )
                 )
               )
            |> initModel flags.config flags.targetFilename


usage : String
usage =
    "Usage: 'node main.js <name of file to scan> <config file path> --debug' \n     '<config file path>' and '--debug' are optional.  '<config file path>' defaults to './sampleConfig' (see main.js for more details).\n"


type Msg
    = Exit ()
    | ReadFileComplete String (Result String Buffer)
    | ScannerComplete (Result ( Scanner.Name, Scanner.Error ) Scanner.Name)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        processTestsComplete testsComplete errorOccurred =
            model.scannerConfig.debug
                ?! ( \_ -> DebugF.log "TestsComplete" ((Basics.toString testsComplete) ++ " of " ++ (Basics.toString model.numberOfTests)), always "" )
                |> (\_ ->
                        (testsComplete >= model.numberOfTests)
                            ? ( Task.perform Exit <| Task.succeed ()
                              , Cmd.none
                              )
                            |> (\cmd -> ({ model | testsComplete = testsComplete, errorOccurred = (errorOccurred ? ( True, model.errorOccurred )) } ! [ cmd ]))
                   )
    in
        case msg of
            Exit _ ->
                model ! [ exitApp <| model.errorOccurred ? ( 1, 0 ) ]

            ReadFileComplete filename (Err error) ->
                let
                    l =
                        DebugF.log "ReadFileComplete Error" error
                in
                    ({ model | errorOccurred = True } ! [ Task.perform Exit <| Task.succeed () ])

            ReadFileComplete filename (Ok buffer) ->
                let
                    l =
                        DebugF.log "ReadFileComplete" filename
                in
                    buildTestCmds model.scannerConfig filename buffer
                        |> (\cmds -> ({ model | numberOfTests = List.length cmds } ! cmds))

            ScannerComplete (Err ( name, error )) ->
                let
                    l =
                        DebugF.log "ScannerComplete Error" { scanName = name, error = error }
                in
                    processTestsComplete (model.testsComplete + 1) True

            ScannerComplete (Ok name) ->
                let
                    l =
                        DebugF.log "ScannerComplete" name
                in
                    processTestsComplete (model.testsComplete + 1) False


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


base64TestString : String
base64TestString =
    "This is an encoded base64 test string!"


testString : String
testString =
    "This is a test string!"


buildTestCmds : Scanner.Config -> String -> Buffer -> List (Cmd Msg)
buildTestCmds config testfile buffer =
    [ Scanner.scanFile config testfile ScannerComplete
    , Scanner.scanString config ("scanString BASE64 TEST (targetString: '" ++ base64TestString ++ "')") (encodeString Base64 base64TestString) Base64 ScannerComplete
    , Scanner.scanString config ("scanString TEST (targetString: '" ++ testString ++ "')") testString Utf8 ScannerComplete
    , Scanner.scanBuffer config ("scanBuffer TEST (buffer created from " ++ testfile ++ " contents)") buffer ScannerComplete
    , Scanner.scanString config ("scanString BASE64 TEST (string created from " ++ testfile ++ " contents)") (encodeBuffer Base64 buffer) Base64 ScannerComplete
    ]


readFileCmd : String -> Cmd Msg
readFileCmd filename =
    NodeFileSystem.readFile filename
        |> Task.mapError (\error -> NodeError.message error)
        |> Task.attempt (ReadFileComplete filename)


encodeString : Encoding -> String -> String
encodeString encoding str =
    (Buffer.fromString Encoding.Utf8 str
        |> Result.andThen (Buffer.toString encoding)
        |> Result.mapError NodeError.message
    )
        ??= (\error -> Debug.crash ("encodeString error: " ++ error))


encodeBuffer : Encoding -> Buffer -> String
encodeBuffer encoding buffer =
    Buffer.toString encoding buffer
        ??= (\error -> Debug.crash ("encodeBuffer error: " ++ (NodeError.message error)))
