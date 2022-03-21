port module Main exposing (main)

import Browser exposing (Document)
import Game
import GameSelection
import Html exposing (Html, div, main_)
import Html.Attributes exposing (class)
import Json.Decode as Decode exposing (Decoder, Error)
import Lib exposing (delay)
import PlayerCreation
import String


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- PORTS


port messageReceiver : (Decode.Value -> a) -> Sub a



-- MODEL


type Model
    = Init -- used to prevent flashing the loader when starting the app
    | Loading
    | PlayerCreation PlayerCreation.Model
    | GameSelection GameSelection.Model
    | Game Game.Model


init : () -> ( Model, Cmd Msg )
init _ =
    ( Init, delay 500 InitDelayExpired )



-- UPDATE


type Msg
    = InitDelayExpired
    | ReceiveModel (Result Error Model)
    | PlayerCreationMessage PlayerCreation.Message
    | GameSelectionMessage GameSelection.Message
    | GameMessage Game.Message


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case ( model, message ) of
        ( Init, InitDelayExpired ) ->
            ( Loading, Cmd.none )

        ( _, ReceiveModel (Ok model1) ) ->
            ( model1, Cmd.none )

        ( _, ReceiveModel (Err _) ) ->
            ( model, Cmd.none )

        ( PlayerCreation playerCreationModel, PlayerCreationMessage playerCreationMessage ) ->
            let
                ( playerCreationModel1, command ) =
                    PlayerCreation.update playerCreationMessage playerCreationModel
            in
            ( PlayerCreation playerCreationModel1, Cmd.map PlayerCreationMessage command )

        ( GameSelection gameSelectionModel, GameSelectionMessage gameSelectionMessage ) ->
            let
                ( gameSelectionModel1, command ) =
                    GameSelection.update gameSelectionMessage gameSelectionModel
            in
            ( GameSelection gameSelectionModel1, Cmd.map GameSelectionMessage command )

        ( Game gameModel, GameMessage gameMessage ) ->
            let
                ( gameModel1, command ) =
                    Game.update gameMessage gameModel
            in
            ( Game gameModel1, Cmd.map GameMessage command )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    messageReceiver <| Decode.decodeValue (modelDecoder model) >> ReceiveModel


modelDecoder : Model -> Decoder Model
modelDecoder model =
    Decode.oneOf
        [ decodeLoading
        , Decode.map PlayerCreation <| PlayerCreation.modelDecoder <| getPlayerCreationModel model
        , Decode.map GameSelection <| GameSelection.modelDecoder <| getGameSelectionModel model
        , Decode.map Game Game.modelDecoder
        ]


decodeLoading : Decoder Model
decodeLoading =
    Decode.field "Loading" <| Decode.succeed Loading


getPlayerCreationModel : Model -> Maybe PlayerCreation.Model
getPlayerCreationModel model =
    case model of
        PlayerCreation playerCreationModel ->
            Just playerCreationModel

        _ ->
            Nothing


getGameSelectionModel : Model -> Maybe GameSelection.Model
getGameSelectionModel model =
    case model of
        GameSelection gameSelectionModel ->
            Just gameSelectionModel

        _ ->
            Nothing



-- VIEW


view : Model -> Document Msg
view model =
    { title = title model
    , body = body model
    }


title : Model -> String
title _ =
    "Dart"


body : Model -> List (Html Msg)
body model =
    [ case model of
        Init ->
            main_ [] []

        Loading ->
            bodyLoading

        PlayerCreation playerCreationModel ->
            Html.map PlayerCreationMessage (PlayerCreation.body playerCreationModel)

        GameSelection gameSelectionModel ->
            Html.map GameSelectionMessage (GameSelection.body gameSelectionModel)

        Game gameModel ->
            Html.map GameMessage (Game.body gameModel)
    ]


bodyLoading : Html Msg
bodyLoading =
    main_ [ class "loading fill" ]
        [ div [ class "spinner-outer" ]
            [ div [ class "spinner" ] []
            ]
        ]
