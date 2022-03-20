module PlayerCreation exposing (..)

import Html exposing (Html, button, div, h1, h5, input, main_, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (attribute, autofocus, class, id, placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Lib exposing (sendJsonMessage)
import List
import String



-- MODEL


type alias Model =
    { players : List Player
    , newPlayerName : String
    }


type alias Player =
    { uuid : String
    , name : String
    }



-- UPDATE


type Message
    = NewPlayerNameChange String
    | AddPlayer
    | RemovePlayer String
    | NewGame


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        NewPlayerNameChange newPlayerName ->
            ( { model | newPlayerName = newPlayerName }, Cmd.none )

        AddPlayer ->
            ( { model | newPlayerName = "" }, addPlayer model.newPlayerName )

        RemovePlayer uuid ->
            ( model, removePlayer uuid )

        NewGame ->
            ( model, newGame )


addPlayer : String -> Cmd Message
addPlayer name =
    sendJsonMessage <| Encode.object [ ( "AddPlayer", Encode.object [ ( "name", Encode.string name ) ] ) ]


removePlayer : String -> Cmd Message
removePlayer uuid =
    sendJsonMessage <| Encode.object [ ( "RemovePlayer", Encode.object [ ( "uuid", Encode.string uuid ) ] ) ]


newGame : Cmd Message
newGame =
    sendJsonMessage <| Encode.object [ ( "NewGame", Encode.object [] ) ]



-- SUBSCRIPTIONS


modelDecoder : Maybe Model -> Decoder Model
modelDecoder model =
    Decode.field "PlayerCreation" <| modelDecoder1 model


modelDecoder1 : Maybe Model -> Decoder Model
modelDecoder1 model =
    let
        newPlayerName =
            Maybe.withDefault "" <| Maybe.map (\model1 -> model1.newPlayerName) model
    in
    Decode.map2 Model (Decode.field "players" playersDecoder) (Decode.succeed newPlayerName)


playersDecoder : Decoder (List Player)
playersDecoder =
    Decode.list <|
        Decode.map2 Player
            (Decode.field "uuid" Decode.string)
            (Decode.field "name" Decode.string)



-- VIEW


body : Model -> Html Message
body model =
    main_ [ class "container" ]
        [ div [ class "row mt-4" ]
            [ div [ class "col" ]
                [ h1 [] [ text "Dart" ]
                ]
            ]
        , div [ class "row mb-1" ]
            [ div [ class "col" ]
                [ table [ class "table table-bordered table-hover" ]
                    [ thead [ class "thead-light" ]
                        [ tr []
                            [ th [] [ text "Player" ]
                            ]
                        ]
                    , tbody [] ([] ++ List.map renderPlayer model.players)
                    ]
                ]
            ]
        , div [ class "row" ]
            [ div [ class "col text-center" ]
                [ button [ class "btn btn-outline-success game-button", attribute "data-target" "#modal-new-player", attribute "data-toggle" "modal" ] [ text "Add player" ]
                , button [ class "btn btn-primary game-button", onClick NewGame ] [ text "New Game" ]
                ]
            ]
        , div [ class "modal fade", id "modal-new-player", attribute "role" "dialog" ]
            [ div [ class "modal-dialog" ]
                [ div [ class "modal-content" ]
                    [ div [ class "modal-header" ]
                        [ h5 [] [ text "New player" ]
                        ]
                    , div [ class "modal-body" ]
                        [ input [ class "form-control", type_ "text", placeholder "Name", autofocus True, onInput NewPlayerNameChange, value model.newPlayerName ] []
                        ]
                    , div [ class "modal-footer" ]
                        [ button [ class "btn btn-secondary", attribute "data-dismiss" "modal" ] [ text "Close" ]
                        , button [ class "btn btn-primary", attribute "data-dismiss" "modal", onClick AddPlayer ] [ text "Add player" ]
                        ]
                    ]
                ]
            ]
        ]


renderPlayer : Player -> Html Message
renderPlayer player =
    tr []
        [ td []
            [ text player.name
            , button [ class "close", onClick (RemovePlayer player.uuid) ] [ span [ attribute "aria-hidden" "true" ] [ text "×" ] ]
            ]
        ]
