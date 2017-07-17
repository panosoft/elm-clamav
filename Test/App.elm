port module App exposing (..)

-- Needed otherwise Json.Decode is not included in compiled js

import Json.Decode
import Task exposing (fail)
import Scanner exposing (..)
import Node.Encoding as Encoding exposing (..)
import Node.Global exposing (parseInt)
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
    parseInt 10 flags.clamavPort
        |??>
            (\possiblePort ->
                (isNaN (toFloat possiblePort)
                    ?! ( (\_ -> Debug.crash ("Invalid clavavPort: " ++ flags.clamavPort)), always possiblePort )
                )
                    |> (\clamavPort ->
                            Scanner.config flags.clamavHost clamavPort
                                |> (\config -> model ! [ Scanner.scanString config "scanString TEST" "hi there" Utf8 ScannerComplete ])
                       )
            )
        ??= (\error -> Debug.crash ("Invalid clavavPort: " ++ (NodeError.message error)))


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
