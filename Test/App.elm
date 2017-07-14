port module App exposing (..)

-- Needed otherwise Json.Decode is not included in compiled js

import Json.Decode
import Scanner exposing (..)
import Node.Encoding as Encoding exposing (..)


port exitApp : Float -> Cmd msg


port externalStop : (() -> msg) -> Sub msg


type alias Flags =
    { clamavHost : String
    , clamavPort : Int
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
    let
        config =
            Scanner.config flags.clamavHost flags.clamavPort
    in
        model
            ! [ Scanner.scanString config "test" "hi there" Utf8 ScannerComplete ]


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
