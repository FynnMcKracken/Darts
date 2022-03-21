module GameSelection exposing (..)

import Html exposing (Html, button, div, h1, input, label, main_, text)
import Html.Attributes exposing (checked, class, for, id, type_)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Lib exposing (..)



-- MODEL


type alias Model =
    { selectedGameMode : GameMode
    }



-- UPDATE


type Message
    = SelectGameMode GameMode
    | StartGame
    | Back


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        SelectGameMode gameMode ->
            ( { model | selectedGameMode = gameMode }, Cmd.none )

        StartGame ->
            ( model, startGame model.selectedGameMode )

        Back ->
            ( model, back )


startGame : GameMode -> Cmd Message
startGame gameMode =
    sendJsonMessage <| Encode.object [ ( "StartGame", Encode.object [ ( "gameMode", encodeGameMode gameMode ) ] ) ]


back : Cmd Message
back =
    sendJsonMessage <| Encode.object [ ( "Back", Encode.object [] ) ]



-- SUBSCRIPTIONS


modelDecoder : Maybe Model -> Decoder Model
modelDecoder model =
    Decode.field "GameSelection" <| modelDecoder1 model


modelDecoder1 : Maybe Model -> Decoder Model
modelDecoder1 model =
    let
        selectedGameMode =
            Maybe.withDefault Standard <| Maybe.map (\model1 -> model1.selectedGameMode) model
    in
    Decode.map Model (Decode.succeed selectedGameMode)



-- VIEW


body : Model -> Html Message
body model =
    main_ [ class "container" ]
        [ div [ class "row mt-4" ]
            [ div [ class "col" ]
                [ h1 [] [ text "Dart" ]
                , gameModeRadio model Standard
                , gameModeRadio model Cricket
                , button [ class "btn btn-outline-secondary game-button", onClick Back ] [ text "Back" ]
                , button [ class "btn btn-primary game-button", onClick StartGame ] [ text "Start Game" ]
                ]
            ]
        ]


gameModeRadio : Model -> GameMode -> Html Message
gameModeRadio model gameMode =
    div [ class "form-check" ]
        [ input [ class "form-check-input", type_ "radio", id ("game-mode-radio-" ++ gameModeToString gameMode), onInput (\_ -> SelectGameMode gameMode), checked (model.selectedGameMode == gameMode) ] []
        , label [ class "form-check-label", for ("game-mode-radio-" ++ gameModeToString gameMode) ] [ text (gameModeToString gameMode) ]
        ]
