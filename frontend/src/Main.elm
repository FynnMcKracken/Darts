port module Main exposing (main)

import Browser exposing (Document)
import Html exposing (Html, button, div, h1, h5, input, main_, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (attribute, autofocus, class, classList, disabled, href, id, placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode exposing (Decoder, Error)
import Json.Encode as Encode
import List exposing (foldr, singleton)
import Maybe
import String
import Svg exposing (Svg, circle, line, path, polyline, svg)
import Svg.Attributes exposing (cx, cy, d, height, points, r, viewBox, width, x1, x2, y1, y2)


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- PORTS


port sendMessage : String -> Cmd msg


port messageReceiver : (Decode.Value -> msg) -> Sub msg



-- MODEL


type GameMode
    = Standard
    | Cricket

type alias Model =
    { selectMode : GameMode
    , currentPlayer : Int
    , newPlayerName : String
    , gameState : GameState1
    }

type GameState1
    = Loading
    | Loaded GameState

type alias GameState =
    { mode : GameMode
    , running : Bool
    , lastHit : Maybe String
    , players : List Player
    }

type alias Player =
    { uuid : String
    , name : String
    , score : List ( String, Int )
    , hits : List String
    , state : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { currentPlayer = 0, newPlayerName = "", selectMode = Standard, gameState = Loading }, Cmd.none )



-- UPDATE


type Msg
    = Recv (Result Error GameState)
    | StartGame
    | NextPlayer
    | NewPlayerNameChange String
    | AddNewPlayer
    | ResetScore
    | MissHit
    | RemovePlayer String
    | SelectGameMode GameMode
    | ChangeGameMode GameMode


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Recv (Ok state1) ->
            ( { model | gameState = Loaded state1 }, Cmd.none )

        Recv (Err _) ->
            ( model, Cmd.none )

        StartGame ->
            ( model, sendMessage (Encode.encode 0 (Encode.object [ ( "startGame", Encode.null ) ])) )

        NextPlayer ->
            ( model, sendMessage (Encode.encode 0 (Encode.object [ ( "nextPlayer", Encode.null ) ])) )

        ResetScore ->
            ( model, sendMessage (Encode.encode 0 (Encode.object [ ( "resetScore", Encode.null ) ])) )

        MissHit ->
            ( model, sendMessage (Encode.encode 0 (Encode.object [ ( "missHit", Encode.null ) ])) )

        NewPlayerNameChange name ->
            ( { model | newPlayerName = name }, Cmd.none )

        AddNewPlayer ->
            ( { model | newPlayerName = "" }, sendMessage (Encode.encode 0 (Encode.object [ ( "newPlayer", Encode.string model.newPlayerName ) ])) )

        RemovePlayer uuid ->
            ( model, sendMessage (Encode.encode 0 (removePlayer uuid)) )

        SelectGameMode Standard ->
            ( { model | selectMode = Standard }, Cmd.none )

        SelectGameMode Cricket ->
            ( { model | selectMode = Cricket }, Cmd.none )

        ChangeGameMode Standard ->
            ( model, sendMessage (Encode.encode 0 (Encode.object [ ( "gameMode", Encode.string "Standard" ) ])) )

        ChangeGameMode Cricket ->
            ( model, sendMessage (Encode.encode 0 (Encode.object [ ( "gameMode", Encode.string "Cricket" ) ])) )


removePlayer : String -> Encode.Value
removePlayer uuid =
    Encode.object [ ( "removePlayer", Encode.string uuid ) ]



-- SUBSCRIPTIONS




subscriptions : Model -> Sub Msg
subscriptions _ =
    messageReceiver (decodeSuggestions >> Recv)


decodeSuggestions : Decode.Value -> Result Error GameState
decodeSuggestions =
    Decode.decodeValue gameStateDecoder


gameStateDecoder : Decoder GameState
gameStateDecoder =
    Decode.map4 GameState
        (Decode.field "gameMode" Decode.string |> Decode.andThen gameModeDecoder)
        (Decode.field "running" Decode.bool)
        (Decode.maybe (Decode.field "lastHit" Decode.string))
        (Decode.field "players" playersDecoder)


gameModeDecoder : String -> Decoder GameMode
gameModeDecoder gameMode =
    case gameMode of
        "Standard" ->
            Decode.succeed Standard

        "Cricket" ->
            Decode.succeed Cricket

        _ ->
            Decode.fail ("The string " ++ gameMode ++ " is not a valid game mode")


playersDecoder : Decoder (List Player)
playersDecoder =
    Decode.list
        (Decode.map5 Player
            (Decode.field "uuid" Decode.string)
            (Decode.field "name" Decode.string)
            (Decode.field "score" (Decode.keyValuePairs Decode.int))
            (Decode.field "hits" (Decode.list Decode.string))
            (Decode.field "state" Decode.string)
        )



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
  case model.gameState of
    Loading -> bodyLoading
    Loaded gameState -> bodyLoaded model gameState


bodyLoading : List (Html Msg)
bodyLoading =
    [ main_ [ class "container" ]
        [ div [ class "row mt-4" ]
            [ div [ class "col" ]
                [ h1 [] [ text "Dart" ]
                , div [] [ text "Loading…" ]
                ]
            ]
        ]
    ]


bodyLoaded : Model -> GameState -> List (Html Msg)
bodyLoaded model gameState =
    [ main_ [ class "container" ]
        [ div [ class "row mt-4" ]
            [ div [ class "col" ]
                [ h1 [] [ text "Dart" ]
                , div [] [ text ("last hit: " ++ Maybe.withDefault "-" gameState.lastHit) ]
                ]
            , div [ class "col text-right" ]
                [ div [ class "dropdown" ]
                    [ button [ class "btn btn-secondary dropdown-toggle", href "#", attribute "role" "button", id "dropdownMenuButton", attribute "data-toggle" "dropdown" ] [ text "Game Mode" ]
                    , div [ class "dropdown-menu", attribute "aria-labelledby" "dropdownMenuButton" ]
                        [ button [ class "dropdown-item", classList [ ( "active", gameState.mode == Standard ) ], attribute "type" "button", attribute "data-target" "#modal-change-mode", attribute "data-toggle" "modal", onClick (SelectGameMode Standard) ] [ text "Standard 501" ]
                        , button [ class "dropdown-item", classList [ ( "active", gameState.mode == Cricket ) ], attribute "type" "button", attribute "data-target" "#modal-change-mode", attribute "data-toggle" "modal",  onClick (SelectGameMode Cricket) ] [ text "Cricket Light" ]
                        ]
                    ]
                ]
            ]
        , div [ class "row mb-4" ]
            [ div [ class "col" ]
                [ table [ class "table table-bordered table-hover" ]
                    [ thead [ class "thead-light" ]
                        [ tr []
                            [ th [] [ text "Player" ]
                            , th [] [ text "Hits" ]
                            , th [] [ text "Score" ]
                            ]
                        ]
                    , tbody [] ([] ++ List.map (renderRow gameState.mode) gameState.players)
                    ]
                ]
            ]
        , div [ class "row mt-4" ]
            [ div [ class "col" ]
                [ button [ class "btn btn-primary game-button", disabled (not gameState.running), onClick NextPlayer ] [ text "Next player" ]
                , button [ class "btn btn-outline-secondary game-button", disabled gameState.running, attribute "data-target" "#modal-new-player", attribute "data-toggle" "modal" ] [ text "Add player" ]
                ]
            , div [ class "col text-center" ]
                [ button [ class "btn btn-success", disabled gameState.running, onClick StartGame ] [ text "Start game" ]
                ]
            , div [ class "col text-right" ]
                [ button [ class "btn btn-outline-danger game-button", disabled (not gameState.running), attribute "data-target" "#modal-reset-score", attribute "data-toggle" "modal" ] [ text "Reset game" ]
                , button [ class "btn btn-danger", disabled (not gameState.running), onClick MissHit ] [ text "Missed hit" ]
                ]
            ]
        , div [ class "row mb-2" ]
            [ div [ class "col mb-2 text-center" ]
                [ dartBoard gameState
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
                        , button [ class "btn btn-primary", attribute "data-dismiss" "modal", onClick AddNewPlayer ] [ text "Add player" ]
                        ]
                    ]
                ]
            ]
        , div [ class "modal fade", id "modal-reset-score", attribute "role" "dialog" ]
            [ div [ class "modal-dialog" ]
                [ div [ class "modal-content" ]
                    [ div [ class "modal-header" ]
                        [ h5 [] [ text "Reset game" ]
                        ]
                    , div [ class "modal-body" ]
                        [ text "Do you want to reset the current game?"
                        ]
                    , div [ class "modal-footer" ]
                        [ button [ class "btn btn-secondary", attribute "data-dismiss" "modal" ] [ text "Close" ]
                        , button [ class "btn btn-danger", attribute "data-dismiss" "modal", onClick ResetScore ] [ text "Reset" ]
                        ]
                    ]
                ]
            ]
        , div [ class "modal fade", id "modal-change-mode", attribute "role" "dialog" ]
            [ div [ class "modal-dialog" ]
                [ div [ class "modal-content" ]
                    [ div [ class "modal-header" ]
                        [ h5 [] [ text "Change game mode" ]
                        ]
                    , div [ class "modal-body" ]
                        [ text "Do you want to change the game mode and reset the current game?"
                        ]
                    , div [ class "modal-footer" ]
                        [ button [ class "btn btn-secondary", attribute "data-dismiss" "modal" ] [ text "Close" ]
                        , button [ class "btn btn-primary", attribute "data-dismiss" "modal", onClick (ChangeGameMode model.selectMode) ] [ text "Change" ]
                        ]
                    ]
                ]
            ]
        ]
    ]


renderRow : GameMode -> Player -> Html Msg
renderRow gameMode player =
    tr [ classList [ ( "table-primary", player.state == "Playing" ), ( "table-success", player.state == "Finished" ), ( "table-secondary", player.state == "Blocked" ) ] ]
        [ td []
            [ text player.name
            , button [ class "close", onClick (RemovePlayer player.uuid) ] [ span [ attribute "aria-hidden" "true" ] [ text "×" ] ]
            ]
        , td [ class "hits-cell" ] ([] ++ List.map renderHit player.hits)
        , td [] ([] ++ singleton (renderScore gameMode player.score))
        ]


renderHit : String -> Html Msg
renderHit hit =
    div [ class "badge badge-pill hit-badge", classList [ ( "badge-danger", hit == "Miss" ), ( "badge-success", hit /= "Miss" ) ] ] [ text hit ]


renderScore : GameMode -> List ( String, Int ) -> Html Msg
renderScore gameMode scores =
    case gameMode of
        Standard ->
            div [] ([] ++ List.map (\score -> text <| String.fromInt score) (List.map Tuple.second scores))

        Cricket ->
            table [] ([] ++ renderCricketScore scores)


renderCricketScore : List ( String, Int ) -> List (Html Msg)
renderCricketScore scores =
    [ thead []
        [ tr [] ([] ++ List.map (\field -> th [] [ text field ]) (List.map Tuple.first scores)) ]
    , tbody []
        [ tr [] ([] ++ List.map renderCricketPoints scores) ]
    ]


renderCricketPoints : ( String, Int ) -> Html Msg
renderCricketPoints ( _, score ) =
    td []
        [ div []
            [ cricketMarker score
            ]
        ]


justOrNothing : Bool -> a -> Maybe a
justOrNothing condition value =
    if condition then
        Just value

    else
        Nothing


listFlatten : Maybe (Svg msg) -> List (Svg msg) -> List (Svg msg)
listFlatten value list =
    case value of
        Just val ->
            list ++ [ val ]

        Nothing ->
            []


cricketMarker : Int -> Html msg
cricketMarker state =
    svg [ width "20", height "20", viewBox "0 0 32 32" ]
        (foldr listFlatten
            []
            [ justOrNothing (state >= 1) (line [ x1 "2", y1 "30", x2 "30", y2 "2", style "fill" "none", style "stroke" "#000", style "stroke-width" "4px" ] [])
            , justOrNothing (state >= 2) (line [ x1 "2", y1 "2", x2 "30", y2 "30", style "fill" "none", style "stroke" "#000", style "stroke-width" "4px" ] [])
            , justOrNothing (state >= 3) (circle [ cx "16", cy "16", r "14", style "fill" "none", style "stroke" "#000", style "stroke-width" "4px" ] [])
            ]
        )


dartBoard : GameState -> Html msg
dartBoard gameState =
    svg [ width "1000", height "1000", viewBox "0 0 1000 1000" ]
        [ segment gameState "12i" "#1d1d1b" "M411.48,326.28,479.57,459.9a44.9,44.9,0,0,0-11.38,8.29l-106-106A196,196,0,0,1,411.48,326.28Z"
        , segment gameState "12o" "#1d1d1b" "M345.66,197.09l47.58,93.39a235.5,235.5,0,0,0-59.45,43.31L259.7,259.7A341.92,341.92,0,0,1,345.66,197.09Z"
        , segment gameState "14o" "#1d1d1b" "M197.09,345.66l93.39,47.58a232.54,232.54,0,0,0-22.64,70L164.16,446.8A337.41,337.41,0,0,1,197.09,345.66Z"
        , segment gameState "14i" "#1d1d1b" "M326.28,411.48l133.63,68.09A45.24,45.24,0,0,0,455.55,493L307.39,469.49A193.28,193.28,0,0,1,326.28,411.48Z"
        , segment gameState "8i" "#1d1d1b" "M459.9,520.43,326.28,588.52a193.28,193.28,0,0,1-18.89-58L455.55,507A45,45,0,0,0,459.9,520.43Z"
        , segment gameState "8o" "#1d1d1b" "M290.48,606.76l-93.39,47.58A337.41,337.41,0,0,1,164.16,553.2l103.68-16.43A232.54,232.54,0,0,0,290.48,606.76Z"
        , segment gameState "7o" "#1d1d1b" "M393.24,709.52l-47.58,93.39a341.92,341.92,0,0,1-86-62.61l74.09-74.09A235.5,235.5,0,0,0,393.24,709.52Z"
        , segment gameState "7i" "#1d1d1b" "M479.57,540.09,411.48,673.72a196,196,0,0,1-49.3-35.9l106-106A45.24,45.24,0,0,0,479.57,540.09Z"
        , segment gameState "3i" "#1d1d1b" "M507,544.45l23.47,148.16a195.94,195.94,0,0,1-61,0L493,544.45A44.92,44.92,0,0,0,507,544.45Z"
        , segment gameState "3o" "#1d1d1b" "M536.77,732.16,553.2,835.84a342.25,342.25,0,0,1-106.4,0l16.43-103.68a239.45,239.45,0,0,0,73.54,0Z"
        , segment gameState "2o" "#1d1d1b" "M666.21,666.21,740.3,740.3a341.92,341.92,0,0,1-86,62.61l-47.58-93.39A235.5,235.5,0,0,0,666.21,666.21Z"
        , segment gameState "2i" "#1d1d1b" "M531.81,531.81l106,106a196,196,0,0,1-49.3,35.9L520.43,540.1A44.9,44.9,0,0,0,531.81,531.81Z"
        , segment gameState "10o" "#1d1d1b" "M732.16,536.77,835.84,553.2a337.41,337.41,0,0,1-32.93,101.14l-93.39-47.58A232.54,232.54,0,0,0,732.16,536.77Z"
        , segment gameState "10i" "#1d1d1b" "M544.45,507l148.16,23.47a193.28,193.28,0,0,1-18.89,58L540.09,520.43A45.24,45.24,0,0,0,544.45,507Z"
        , segment gameState "13i" "#1d1d1b" "M692.61,469.49,544.45,493a45,45,0,0,0-4.35-13.39l133.62-68.09A193.28,193.28,0,0,1,692.61,469.49Z"
        , segment gameState "13o" "#1d1d1b" "M835.84,446.8,732.16,463.23a232.54,232.54,0,0,0-22.64-70l93.39-47.58A337.41,337.41,0,0,1,835.84,446.8Z"
        , segment gameState "18o" "#1d1d1b" "M740.3,259.7l-74.09,74.09a235.5,235.5,0,0,0-59.45-43.31l47.58-93.39A341.92,341.92,0,0,1,740.3,259.7Z"
        , segment gameState "18i" "#1d1d1b" "M637.82,362.18l-106,106a45.24,45.24,0,0,0-11.38-8.28l68.09-133.63A196,196,0,0,1,637.82,362.18Z"
        , segment gameState "20i" "#1d1d1b" "M530.51,307.39,507,455.55a44.92,44.92,0,0,0-14.08,0L469.49,307.39a195.94,195.94,0,0,1,61,0Z"
        , segment gameState "20o" "#1d1d1b" "M553.2,164.16,536.77,267.84a239.45,239.45,0,0,0-73.54,0L446.8,164.16a342.25,342.25,0,0,1,106.4,0Z"
        , segment gameState "5o" "#fff" "M446.8,164.16l16.43,103.68a232.54,232.54,0,0,0-70,22.64l-47.58-93.39A337.41,337.41,0,0,1,446.8,164.16Z"
        , segment gameState "5i" "#fff" "M469.49,307.39,493,455.55a45,45,0,0,0-13.39,4.35L411.48,326.28A193.28,193.28,0,0,1,469.49,307.39Z"
        , segment gameState "9i" "#fff" "M362.18,362.18l106,106a45.24,45.24,0,0,0-8.28,11.38L326.28,411.48A196,196,0,0,1,362.18,362.18Z"
        , segment gameState "9o" "#fff" "M259.7,259.7l74.09,74.09a235.5,235.5,0,0,0-43.31,59.45l-93.39-47.58A341.92,341.92,0,0,1,259.7,259.7Z"
        , segment gameState "11o" "#fff" "M164.16,446.8l103.68,16.43a239.45,239.45,0,0,0,0,73.54L164.16,553.2a342.25,342.25,0,0,1,0-106.4Z"
        , segment gameState "11i" "#fff" "M307.39,469.49,455.55,493a44.92,44.92,0,0,0,0,14.08L307.39,530.51a195.94,195.94,0,0,1,0-61Z"
        , segment gameState "16o" "#fff" "M333.79,666.21,259.7,740.3a341.92,341.92,0,0,1-62.61-86l93.39-47.58A235.5,235.5,0,0,0,333.79,666.21Z"
        , segment gameState "16i" "#fff" "M468.19,531.81l-106,106a196,196,0,0,1-35.9-49.3L459.9,520.43A44.9,44.9,0,0,0,468.19,531.81Z"
        , segment gameState "19o" "#fff" "M463.23,732.16,446.8,835.84a337.41,337.41,0,0,1-101.14-32.93l47.58-93.39A232.54,232.54,0,0,0,463.23,732.16Z"
        , segment gameState "19i" "#fff" "M493,544.45,469.49,692.61a193.28,193.28,0,0,1-58-18.89l68.09-133.63A45.24,45.24,0,0,0,493,544.45Z"
        , segment gameState "17i" "#fff" "M520.43,540.1l68.09,133.62a193.28,193.28,0,0,1-58,18.89L507,544.45A45,45,0,0,0,520.43,540.1Z"
        , segment gameState "17o" "#fff" "M606.76,709.52l47.58,93.39A337.41,337.41,0,0,1,553.2,835.84L536.77,732.16A232.54,232.54,0,0,0,606.76,709.52Z"
        , segment gameState "15o" "#fff" "M709.52,606.76l93.39,47.58a341.92,341.92,0,0,1-62.61,86l-74.09-74.09A235.5,235.5,0,0,0,709.52,606.76Z"
        , segment gameState "15i" "#fff" "M540.09,520.43l133.63,68.09a196,196,0,0,1-35.9,49.3l-106-106A45.24,45.24,0,0,0,540.09,520.43Z"
        , segment gameState "6i" "#fff" "M692.61,469.49a195.94,195.94,0,0,1,0,61L544.45,507a44.92,44.92,0,0,0,0-14.08Z"
        , segment gameState "6o" "#fff" "M835.84,446.8a342.25,342.25,0,0,1,0,106.4L732.16,536.77a239.45,239.45,0,0,0,0-73.54Z"
        , segment gameState "4i" "#fff" "M673.72,411.48,540.1,479.57a44.9,44.9,0,0,0-8.29-11.38l106-106A196,196,0,0,1,673.72,411.48Z"
        , segment gameState "4o" "#fff" "M802.91,345.66l-93.39,47.58a235.5,235.5,0,0,0-43.31-59.45L740.3,259.7A341.92,341.92,0,0,1,802.91,345.66Z"
        , segment gameState "6x2" "#4daf50" "M875.4,440.54a386.59,386.59,0,0,1,0,118.92h-.08l-39.48-6.25a342.25,342.25,0,0,0,0-106.4l39.48-6.25Z"
        , segment gameState "13x2" "#e95226" "M875.4,440.54h-.08l-39.48,6.25a337.41,337.41,0,0,0-32.93-101.14l35.67-18.18.13-.06q6.13,12,11.44,24.6A375.88,375.88,0,0,1,875.4,440.54Z"
        , segment gameState "10x2" "#e95226" "M875.32,559.45h.08A375.88,375.88,0,0,1,850.15,648q-5.29,12.54-11.44,24.6l-.13-.06-35.67-18.18A337.41,337.41,0,0,0,835.84,553.2Z"
        , segment gameState "4x2" "#4daf50" "M838.71,327.42l-.13.06-35.67,18.18a341.92,341.92,0,0,0-62.61-86l28.4-28.4.06-.06A378.45,378.45,0,0,1,838.71,327.42Z"
        , segment gameState "15x2" "#4daf50" "M838.58,672.52l.13.06a378.45,378.45,0,0,1-70,96.18l-.06-.06-28.4-28.4a341.92,341.92,0,0,0,62.61-86Z"
        , segment gameState "18x2" "#e95226" "M768.76,231.24l-.06.06-28.4,28.4a341.92,341.92,0,0,0-86-62.61l18.18-35.67.06-.13A378.45,378.45,0,0,1,768.76,231.24Z"
        , segment gameState "2x2" "#e95226" "M768.7,768.7l.06.06a378.45,378.45,0,0,1-96.18,70l-.06-.13-18.18-35.67a341.92,341.92,0,0,0,86-62.61Z"
        , segment gameState "6x3" "#4daf50" "M732.16,463.23a239.45,239.45,0,0,1,0,73.54l-39.55-6.26a195.94,195.94,0,0,0,0-61Z"
        , segment gameState "13x3" "#e95226" "M732.16,463.23l-39.55,6.26a193.28,193.28,0,0,0-18.89-58l35.8-18.24A232.54,232.54,0,0,1,732.16,463.23Z"
        , segment gameState "10x3" "#e95226" "M692.61,530.51l39.55,6.26a232.54,232.54,0,0,1-22.64,70l-35.8-18.24A193.28,193.28,0,0,0,692.61,530.51Z"
        , segment gameState "4x3" "#4daf50" "M709.52,393.24l-35.8,18.24a196,196,0,0,0-35.9-49.3l28.39-28.39A235.5,235.5,0,0,1,709.52,393.24Z"
        , segment gameState "15x3" "#4daf50" "M673.72,588.52l35.8,18.24a235.5,235.5,0,0,1-43.31,59.45l-28.39-28.39A196,196,0,0,0,673.72,588.52Z"
        , segment gameState "1x2" "#4daf50" "M672.58,161.29l-.06.13-18.18,35.67A337.41,337.41,0,0,0,553.2,164.16l6.25-39.48v-.08A375.88,375.88,0,0,1,648,149.85Q660.52,155.14,672.58,161.29Z"
        , segment gameState "17x2" "#4daf50" "M672.52,838.58l.06.13q-12,6.13-24.6,11.44a375.88,375.88,0,0,1-88.52,25.25v-.08l-6.25-39.48a337.41,337.41,0,0,0,101.14-32.93Z"
        , segment gameState "18x3" "#e95226" "M666.21,333.79l-28.39,28.39a196,196,0,0,0-49.3-35.9l18.24-35.8A235.5,235.5,0,0,1,666.21,333.79Z"
        , segment gameState "2x3" "#e95226" "M637.82,637.82l28.39,28.39a235.5,235.5,0,0,1-59.45,43.31l-18.24-35.8A196,196,0,0,0,637.82,637.82Z"
        , segment gameState "1o" "#fff" "M654.34,197.09l-47.58,93.39a232.54,232.54,0,0,0-70-22.64L553.2,164.16A337.41,337.41,0,0,1,654.34,197.09Z"
        , segment gameState "1x3" "#4daf50" "M606.76,290.48l-18.24,35.8a193.28,193.28,0,0,0-58-18.89l6.26-39.55A232.54,232.54,0,0,1,606.76,290.48Z"
        , segment gameState "17x3" "#4daf50" "M588.52,673.72l18.24,35.8a232.54,232.54,0,0,1-70,22.64l-6.26-39.55A193.28,193.28,0,0,0,588.52,673.72Z"
        , segment gameState "1i" "#fff" "M588.52,326.28,520.43,459.91A45.24,45.24,0,0,0,507,455.55l23.47-148.16A193.28,193.28,0,0,1,588.52,326.28Z"
        , segment gameState "3x2" "#e95226" "M559.45,875.32v.08a386.59,386.59,0,0,1-118.92,0v-.08l6.25-39.48a342.25,342.25,0,0,0,106.4,0Z"
        , segment gameState "20x2" "#e95226" "M559.46,124.6v.08l-6.25,39.48a342.25,342.25,0,0,0-106.4,0l-6.25-39.48v-.08a386.59,386.59,0,0,1,118.92,0Z"
        , segment gameState "Bullseye" "#4daf50" "M544.45,493a44.82,44.82,0,1,1-4.35-13.39A44.92,44.92,0,0,1,544.45,493ZM520,500a20,20,0,1,0-20,20A20,20,0,0,0,520,500Z"
        , segment gameState "3x3" "#e95226" "M530.51,692.61l6.26,39.55a239.45,239.45,0,0,1-73.54,0l6.26-39.55a195.94,195.94,0,0,0,61,0Z"
        , segment gameState "20x3" "#e95226" "M536.77,267.84l-6.26,39.55a195.94,195.94,0,0,0-61,0l-6.26-39.55a239.45,239.45,0,0,1,73.54,0Z"
        , segment gameState "19x3" "#4daf50" "M469.49,692.61l-6.26,39.55a232.54,232.54,0,0,1-70-22.64l18.24-35.8A193.28,193.28,0,0,0,469.49,692.61Z"
        , segment gameState "5x3" "#4daf50" "M463.23,267.84l6.26,39.55a193.28,193.28,0,0,0-58,18.89l-18.24-35.8A232.54,232.54,0,0,1,463.23,267.84Z"
        , segment gameState "19x2" "#4daf50" "M446.8,835.84l-6.25,39.48v.08A375.88,375.88,0,0,1,352,850.15q-12.54-5.29-24.6-11.44l.06-.13,18.18-35.67A337.41,337.41,0,0,0,446.8,835.84Z"
        , segment gameState "5x2" "#4daf50" "M440.55,124.68l6.25,39.48a337.41,337.41,0,0,0-101.14,32.93l-18.18-35.67-.06-.13q12-6.14,24.6-11.44a375.88,375.88,0,0,1,88.52-25.25Z"
        , segment gameState "12x3" "#e95226" "M393.24,290.48l18.24,35.8a196,196,0,0,0-49.3,35.9l-28.39-28.39A235.5,235.5,0,0,1,393.24,290.48Z"
        , segment gameState "7x3" "#e95226" "M411.48,673.72l-18.24,35.8a235.5,235.5,0,0,1-59.45-43.31l28.39-28.39A196,196,0,0,0,411.48,673.72Z"
        , segment gameState "16x3" "#4daf50" "M362.18,637.82l-28.39,28.39a235.5,235.5,0,0,1-43.31-59.45l35.8-18.24A196,196,0,0,0,362.18,637.82Z"
        , segment gameState "9x3" "#4daf50" "M333.79,333.79l28.39,28.39a196,196,0,0,0-35.9,49.3l-35.8-18.24A235.5,235.5,0,0,1,333.79,333.79Z"
        , segment gameState "12x2" "#e95226" "M327.48,161.42l18.18,35.67a341.92,341.92,0,0,0-86,62.61l-28.4-28.4-.06-.06a378.45,378.45,0,0,1,96.18-70Z"
        , segment gameState "7x2" "#e95226" "M345.66,802.91l-18.18,35.67-.06.13a378.45,378.45,0,0,1-96.18-70l.06-.06,28.4-28.4A341.92,341.92,0,0,0,345.66,802.91Z"
        , segment gameState "14x3" "#e95226" "M290.48,393.24l35.8,18.24a193.28,193.28,0,0,0-18.89,58l-39.55-6.26A232.54,232.54,0,0,1,290.48,393.24Z"
        , segment gameState "8x3" "#e95226" "M326.28,588.52l-35.8,18.24a232.54,232.54,0,0,1-22.64-70l39.55-6.26A193.28,193.28,0,0,0,326.28,588.52Z"
        , segment gameState "11x3" "#4daf50" "M267.84,463.23l39.55,6.26a195.94,195.94,0,0,0,0,61l-39.55,6.26a239.45,239.45,0,0,1,0-73.54Z"
        , segment gameState "16x2" "#4daf50" "M259.7,740.3l-28.4,28.4-.06.06a378.45,378.45,0,0,1-70-96.18l.13-.06,35.67-18.18A341.92,341.92,0,0,0,259.7,740.3Z"
        , segment gameState "9x2" "#4daf50" "M231.3,231.3l28.4,28.4a341.92,341.92,0,0,0-62.61,86l-35.67-18.18-.13-.06a378.45,378.45,0,0,1,70-96.18Z"
        , segment gameState "14x2" "#e95226" "M161.42,327.48l35.67,18.18A337.41,337.41,0,0,0,164.16,446.8l-39.48-6.25h-.08A375.88,375.88,0,0,1,149.85,352q5.29-12.54,11.44-24.6Z"
        , segment gameState "8x2" "#e95226" "M197.09,654.34l-35.67,18.18-.13.06q-6.14-12-11.44-24.6a375.88,375.88,0,0,1-25.25-88.52h.08l39.48-6.25A337.41,337.41,0,0,0,197.09,654.34Z"
        , segment gameState "11x2" "#4daf50" "M124.68,440.55l39.48,6.25a342.25,342.25,0,0,0,0,106.4l-39.48,6.25h-.08a386.59,386.59,0,0,1,0-118.92Z"
        , circleSegment gameState "Bullseyex2" "#e95226" "500" "500" "20"
        , path [ d "M536.77,732.16a239.45,239.45,0,0,1-73.54,0,232.54,232.54,0,0,1-70-22.64A237,237,0,0,1,290.48,606.76a232.54,232.54,0,0,1-22.64-70,239.45,239.45,0,0,1,0-73.54,232.54,232.54,0,0,1,22.64-70A237,237,0,0,1,393.24,290.48a232.54,232.54,0,0,1,70-22.64,239.45,239.45,0,0,1,73.54,0,232.54,232.54,0,0,1,70,22.64A237,237,0,0,1,709.52,393.24a232.54,232.54,0,0,1,22.64,70,239.45,239.45,0,0,1,0,73.54,232.54,232.54,0,0,1-22.64,70A237,237,0,0,1,606.76,709.52,232.54,232.54,0,0,1,536.77,732.16Z", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M530.51,307.39a194.69,194.69,0,1,0,58,18.89A194.25,194.25,0,0,0,530.51,307.39Z", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M559.46,875.4a386.59,386.59,0,0,1-118.92,0A375.88,375.88,0,0,1,352,850.15q-12.54-5.29-24.6-11.44A381.28,381.28,0,0,1,161.29,672.58q-6.14-12-11.44-24.6a375.88,375.88,0,0,1-25.25-88.52,386.59,386.59,0,0,1,0-118.92A375.88,375.88,0,0,1,149.85,352q5.29-12.54,11.44-24.6A381.28,381.28,0,0,1,327.42,161.29q12-6.14,24.6-11.44a375.88,375.88,0,0,1,88.52-25.25,386.59,386.59,0,0,1,118.92,0A375.88,375.88,0,0,1,648,149.85q12.54,5.29,24.6,11.44A381.28,381.28,0,0,1,838.71,327.42q6.13,12,11.44,24.6a375.88,375.88,0,0,1,25.25,88.52,386.59,386.59,0,0,1,0,118.92A375.88,375.88,0,0,1,850.15,648q-5.29,12.54-11.44,24.6A381.28,381.28,0,0,1,672.58,838.71q-12,6.13-24.6,11.44A375.88,375.88,0,0,1,559.46,875.4Z", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M553.2,164.16a339.31,339.31,0,1,0,101.14,32.93A340.7,340.7,0,0,0,553.2,164.16Z", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "559.45 875.32 553.2 835.84 536.77 732.16 530.51 692.61 507.04 544.45", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "520.43 540.1 588.52 673.72 606.76 709.52 654.34 802.91 672.52 838.58", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "531.81 531.81 637.82 637.82 666.21 666.21 740.3 740.3 768.7 768.7", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "540.09 520.43 673.72 588.52 709.52 606.76 802.91 654.34 838.58 672.52", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "544.45 507.04 692.61 530.51 732.16 536.77 835.84 553.2 875.32 559.45", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "875.32 440.55 835.84 446.8 732.16 463.23 692.61 469.49 544.45 492.96", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "838.58 327.48 802.91 345.66 709.52 393.24 673.72 411.48 540.1 479.57", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "768.7 231.3 740.3 259.7 666.21 333.79 637.82 362.18 531.81 468.19", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "672.52 161.42 654.34 197.09 606.76 290.48 588.52 326.28 520.43 459.91", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "559.45 124.68 553.2 164.16 536.77 267.84 530.51 307.39 507.04 455.55", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "440.55 124.68 446.8 164.16 463.23 267.84 469.49 307.39 492.96 455.55", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "479.57 459.9 411.48 326.28 393.24 290.48 345.66 197.09 327.48 161.42", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "468.19 468.19 362.18 362.18 333.79 333.79 259.7 259.7 231.3 231.3", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "459.91 479.57 326.28 411.48 290.48 393.24 197.09 345.66 161.42 327.48", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "124.68 440.55 164.16 446.8 267.84 463.23 307.39 469.49 455.55 492.96", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "455.55 507.04 307.39 530.51 267.84 536.77 164.16 553.2 124.68 559.45", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "459.9 520.43 326.28 588.52 290.48 606.76 197.09 654.34 161.42 672.52", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "468.19 531.81 362.18 637.82 333.79 666.21 259.7 740.3 231.3 768.7", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "479.57 540.09 411.48 673.72 393.24 709.52 345.66 802.91 327.48 838.58", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , polyline [ points "492.96 544.45 469.49 692.61 463.23 732.16 446.8 835.84 440.55 875.32", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M520.43,540.1A45,45,0,0,1,507,544.45", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M479.57,540.09A45.24,45.24,0,0,0,493,544.45", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M479.57,540.09a45.24,45.24,0,0,1-11.38-8.28", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M493,544.45a44.92,44.92,0,0,0,14.08,0", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M455.55,507a45,45,0,0,0,4.35,13.39", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M459.9,520.43a44.9,44.9,0,0,0,8.29,11.38", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M531.81,531.81a44.9,44.9,0,0,1-11.38,8.29", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M531.81,468.19a44.9,44.9,0,0,1,8.29,11.38", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M468.19,468.19a44.9,44.9,0,0,1,11.38-8.29", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M479.57,459.9A45,45,0,0,1,493,455.55", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M520.43,459.91a45.24,45.24,0,0,1,11.38,8.28", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M507,455.55a45.24,45.24,0,0,1,13.39,4.36", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M459.91,479.57a45.24,45.24,0,0,1,8.28-11.38", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M540.09,520.43a45.24,45.24,0,0,1-8.28,11.38", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M455.55,507a44.92,44.92,0,0,1,0-14.08", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M544.45,507a45.24,45.24,0,0,1-4.36,13.39", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M544.45,493a44.92,44.92,0,0,1,0,14.08", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M455.55,493a45.24,45.24,0,0,1,4.36-13.39", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M507,455.55a44.92,44.92,0,0,0-14.08,0", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , path [ d "M540.1,479.57A45,45,0,0,1,544.45,493", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        , circle [ cx "500", cy "500", r "20", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px" ] []
        --- 20
        , path [ d "M470.71,94l15.38-20.11a15,15,0,0,0,2.08-3.58,9.27,9.27,0,0,0,.74-3.47v0a5.19,5.19,0,0,0-1.54-4,6.28,6.28,0,0,0-4.4-1.43,6.14,6.14,0,0,0-4.37,1.56,7.08,7.08,0,0,0-2,4.42v0h-6.4v0A16.1,16.1,0,0,1,472.39,61a11.26,11.26,0,0,1,4.36-4,13.1,13.1,0,0,1,6.16-1.39,15.51,15.51,0,0,1,6.73,1.33,9.37,9.37,0,0,1,4.25,3.85,12,12,0,0,1,1.46,6.09v0a13.33,13.33,0,0,1-1,4.79,20.33,20.33,0,0,1-2.71,4.82l-12.77,17h16.69v5.77H470.71Z", style "fill" "#1d1d1b" ] []
        , path [ d "M506.68,96.47q-3.21-3.24-3.2-9V67.77q0-5.83,3.21-9.06t9.38-3.23q6.2,0,9.39,3.22t3.2,9.07V87.43q0,5.82-3.21,9t-9.38,3.23Q509.88,99.71,506.68,96.47Zm14.23-4.21a6.84,6.84,0,0,0,1.56-4.83V67.77a6.91,6.91,0,0,0-1.54-4.84c-1-1.12-2.65-1.68-4.86-1.68s-3.82.56-4.85,1.68a6.87,6.87,0,0,0-1.55,4.84V87.43a6.84,6.84,0,0,0,1.56,4.83,7.81,7.81,0,0,0,9.68,0Z", style "fill" "#1d1d1b" ] []
        --- 5
        , path [ d "M364.45,119a10.37,10.37,0,0,1-4.09-3.72,14.79,14.79,0,0,1-2.1-5.86v0h6v0a5.7,5.7,0,0,0,1.89,3.71,6,6,0,0,0,4.05,1.32,5.41,5.41,0,0,0,4.46-2,8.58,8.58,0,0,0,1.57-5.49v-3.62a8.53,8.53,0,0,0-1.57-5.46,5.41,5.41,0,0,0-4.46-2,5.66,5.66,0,0,0-3,.89,8.44,8.44,0,0,0-2.52,2.5H359.2V76.57H381v5.77H365.2v9.72a8.3,8.3,0,0,1,2.49-1.42,8.17,8.17,0,0,1,2.83-.51,12.27,12.27,0,0,1,6.33,1.55,9.88,9.88,0,0,1,4,4.52,17.08,17.08,0,0,1,1.37,7.17V107a16.46,16.46,0,0,1-1.42,7.17,10.09,10.09,0,0,1-4.11,4.54,12.79,12.79,0,0,1-6.5,1.56A12.5,12.5,0,0,1,364.45,119Z", style "fill" "#1d1d1b" ] []
        --- 12
        , path [ d "M242.32,179.46h-6V142.82l-6.09,3.78v-6.28l6.09-4.1h6Z", style "fill" "#1d1d1b" ] []
        , path [ d "M251.38,174.2l14.9-20.11a15.43,15.43,0,0,0,2-3.58A9.67,9.67,0,0,0,269,147V147a5.27,5.27,0,0,0-1.5-4,6,6,0,0,0-4.27-1.43A5.84,5.84,0,0,0,259,143.1a7.16,7.16,0,0,0-2,4.42v0h-6.2v0a16.16,16.16,0,0,1,2.16-6.35,11.06,11.06,0,0,1,4.22-4,12.47,12.47,0,0,1,6-1.38,14.75,14.75,0,0,1,6.52,1.32,9.29,9.29,0,0,1,4.12,3.86,12.3,12.3,0,0,1,1.41,6.09v0a13.71,13.71,0,0,1-.94,4.79,20.65,20.65,0,0,1-2.62,4.82l-12.38,17h16.17v5.77h-24.1Z", style "fill" "#1d1d1b" ] []
        --- 9
        , path [ d "M164.34,250.9l0,1.07a4.39,4.39,0,0,1-2.22,2,8.76,8.76,0,0,1-3.51.64A9.35,9.35,0,0,1,153.2,253a10.2,10.2,0,0,1-3.6-4.45,16.23,16.23,0,0,1-1.28-6.65v0a16.6,16.6,0,0,1,1.4-7.16,9.88,9.88,0,0,1,4.08-4.52,12.75,12.75,0,0,1,6.45-1.55,12.47,12.47,0,0,1,6.44,1.58,10.07,10.07,0,0,1,4.07,4.58,17,17,0,0,1,1.4,7.22v0a22.82,22.82,0,0,1-.59,4.95,30.73,30.73,0,0,1-1.67,5.22l-.36.79a8.17,8.17,0,0,1-.38.79l-9.11,18.53h-6.47Zm.28-3.75a8.51,8.51,0,0,0,1.54-5.44v0a8.13,8.13,0,0,0-1.54-5.3,6.06,6.06,0,0,0-8.76,0,8.18,8.18,0,0,0-1.54,5.33v0a8.41,8.41,0,0,0,1.54,5.42,5.95,5.95,0,0,0,8.76,0Z", style "fill" "#1d1d1b" ] []
        --- 14
        , path [ d "M88.18,389.44h-6V352.8l-6.09,3.78v-6.27l6.09-4.11h6Z", style "fill" "#1d1d1b" ] []
        , path [ d "M97.29,377.55l14.34-31.32h6.18l-14,31h21v5.62H97.29ZM115.72,364h5.85v25.45h-5.85Z", style "fill" "#1d1d1b" ] []
        --- 11
        , path [ d "M74.73,519.22h-6V482.58l-6.08,3.78v-6.27L68.73,476h6Z", style "fill" "#1d1d1b" ] []
        , path [ d "M94.75,519.22h-6V482.58l-6.08,3.78v-6.27L88.75,476h6Z", style "fill" "#1d1d1b" ] []
        --- 8
        , path [ d "M93.75,648a10.82,10.82,0,0,1-4.54-4.21,12.22,12.22,0,0,1-1.61-6.32v-.72a12.22,12.22,0,0,1,1.61-6.09,10.76,10.76,0,0,1,4.27-4.32,9.46,9.46,0,0,1-3.63-3.61,9.83,9.83,0,0,1-1.36-5v-1a11.6,11.6,0,0,1,1.5-6,10.19,10.19,0,0,1,4.23-4,15,15,0,0,1,12.7,0,10.19,10.19,0,0,1,4.23,4,11.6,11.6,0,0,1,1.5,6v1a9.72,9.72,0,0,1-1.4,5,9.34,9.34,0,0,1-3.69,3.56,11.21,11.21,0,0,1,4.34,4.33,12,12,0,0,1,1.63,6.08v.72a12.22,12.22,0,0,1-1.6,6.32,10.88,10.88,0,0,1-4.54,4.21,16.45,16.45,0,0,1-13.64,0Zm10.49-5.18a6,6,0,0,0,2.46-2.33,6.9,6.9,0,0,0,.86-3.47v-.41a7,7,0,0,0-.86-3.5,6,6,0,0,0-2.46-2.33,8.46,8.46,0,0,0-7.35,0,5.91,5.91,0,0,0-2.45,2.35,6.91,6.91,0,0,0-.87,3.5v.45a6.7,6.7,0,0,0,.87,3.45,6,6,0,0,0,2.45,2.31,8,8,0,0,0,3.68.81A7.73,7.73,0,0,0,104.24,642.79Zm-.5-19.49a5.49,5.49,0,0,0,2.15-2.25,7.11,7.11,0,0,0,.76-3.36v-.42a6.57,6.57,0,0,0-.76-3.21,5.39,5.39,0,0,0-2.15-2.16,7.1,7.1,0,0,0-6.35,0,5.36,5.36,0,0,0-2.14,2.16,6.63,6.63,0,0,0-.77,3.24v.45a6.94,6.94,0,0,0,.77,3.31,5.44,5.44,0,0,0,2.14,2.24,6.85,6.85,0,0,0,6.35,0Z", style "fill" "#1d1d1b" ] []
        --- 16
        , path [ d "M149.49,766.09h-6V729.45l-6.08,3.77V727l6.08-4.11h6Z", style "fill" "#1d1d1b" ] []
        , path [ d "M163.77,765a9.92,9.92,0,0,1-4.07-4.46,16.31,16.31,0,0,1-1.39-7.06v0a24,24,0,0,1,.56-5.06,29.72,29.72,0,0,1,1.61-5.2c.12-.3.25-.59.38-.88l.42-.85,9.28-18.62H177l-10.9,21.57,0-1.08a5.15,5.15,0,0,1,2.14-2.17,6.8,6.8,0,0,1,3.29-.77,10.42,10.42,0,0,1,5.71,1.52,9.46,9.46,0,0,1,3.61,4.41,17.85,17.85,0,0,1,1.24,7v0a16.75,16.75,0,0,1-1.4,7.14,9.9,9.9,0,0,1-4.09,4.52,14.3,14.3,0,0,1-12.89,0Zm10.84-6.08a7.61,7.61,0,0,0,1.54-5.09v0a8.63,8.63,0,0,0-1.62-5.6,5.6,5.6,0,0,0-4.61-2,4.84,4.84,0,0,0-4.15,2,9.33,9.33,0,0,0-1.47,5.62v0a7.48,7.48,0,0,0,1.55,5.07,6.29,6.29,0,0,0,8.76,0Z", style "fill" "#1d1d1b" ] []
        --- 7
        , path [ d "M264.46,821.17l-11,37.83H247l11-37.47H247.2v6.22h-6v-12h23.25Z", style "fill" "#1d1d1b" ] []
        --- 19
        , path [ d "M359.47,918.66h-6V882l-6.08,3.78v-6.28l6.08-4.1h6Z", style "fill" "#1d1d1b" ] []
        , path [ d "M384.31,897.19l0,1.07a4.45,4.45,0,0,1-2.22,2,8.76,8.76,0,0,1-3.51.64,9.36,9.36,0,0,1-5.38-1.58,10.23,10.23,0,0,1-3.6-4.44,16.27,16.27,0,0,1-1.28-6.65v0a16.61,16.61,0,0,1,1.4-7.17,9.93,9.93,0,0,1,4.08-4.52,12.75,12.75,0,0,1,6.45-1.55,12.47,12.47,0,0,1,6.44,1.58,10.12,10.12,0,0,1,4.07,4.58,17,17,0,0,1,1.4,7.23v0a23,23,0,0,1-.59,5,31.31,31.31,0,0,1-1.67,5.22l-.36.79a8,8,0,0,1-.38.78L380,918.66h-6.47Zm.28-3.75a8.51,8.51,0,0,0,1.54-5.44v0a8.1,8.1,0,0,0-1.54-5.29,6,6,0,0,0-8.76,0,8.15,8.15,0,0,0-1.54,5.32v0a8.46,8.46,0,0,0,1.54,5.43,5.94,5.94,0,0,0,8.76,0Z", style "fill" "#1d1d1b" ] []
        --- 3
        , path [ d "M495.94,939.67l-2.73-1.32a10.77,10.77,0,0,1-4.4-3.84,13.82,13.82,0,0,1-2.1-6h6.11a6.57,6.57,0,0,0,1.15,3,5.24,5.24,0,0,0,2.28,1.77,8.43,8.43,0,0,0,3.28.58,6.34,6.34,0,0,0,4.61-1.6,6,6,0,0,0,1.65-4.53v-1.3a7.32,7.32,0,0,0-1.56-5,5.57,5.57,0,0,0-4.41-1.77h-3v-5.77h3a5,5,0,0,0,3.88-1.52,6.14,6.14,0,0,0,1.38-4.28v-1.34a5.23,5.23,0,0,0-1.45-4,5.74,5.74,0,0,0-4.13-1.4,6.37,6.37,0,0,0-2.74.58,5.35,5.35,0,0,0-2,1.79,8.07,8.07,0,0,0-1.22,3h-6.09a16.16,16.16,0,0,1,2.22-6.07,11.06,11.06,0,0,1,4.13-3.84,12.24,12.24,0,0,1,5.74-1.31c3.68,0,6.53,1,8.55,3s3,4.73,3,8.3v.71a9.38,9.38,0,0,1-1.74,5.65,9.72,9.72,0,0,1-4.91,3.51,8.74,8.74,0,0,1,5.43,3.48,11.65,11.65,0,0,1,1.92,6.9v.71a13.49,13.49,0,0,1-1.44,6.46,9.53,9.53,0,0,1-4.19,4.07,14.35,14.35,0,0,1-6.62,1.4Z", style "fill" "#1d1d1b" ] []
        --- 17
        , path [ d "M619.33,918.68h-6V882l-6.08,3.78v-6.27l6.08-4.11h6Z", style "fill" "#1d1d1b" ] []
        , path [ d "M651.1,880.84l-11.05,37.84h-6.38l11.06-37.48H633.85v6.22h-6v-12H651.1Z", style "fill" "#1d1d1b" ] []
        --- 2
        , path [ d "M735.06,853.76l14.9-20.1a15.09,15.09,0,0,0,2-3.59,9.62,9.62,0,0,0,.72-3.46v-.06a5.29,5.29,0,0,0-1.5-4,5.94,5.94,0,0,0-4.26-1.42,5.84,5.84,0,0,0-4.23,1.56,7.08,7.08,0,0,0-2,4.41v0h-6.2v0a16.28,16.28,0,0,1,2.16-6.35,11,11,0,0,1,4.22-4,12.45,12.45,0,0,1,6-1.38,14.76,14.76,0,0,1,6.53,1.32,9.24,9.24,0,0,1,4.11,3.85,12.36,12.36,0,0,1,1.41,6.1v0a13.52,13.52,0,0,1-.94,4.79,20.55,20.55,0,0,1-2.61,4.81l-12.38,17h16.17V859h-24.1Z", style "fill" "#1d1d1b" ] []
        --- 15
        , path [ d "M828.09,766.12h-6V729.48L816,733.25V727l6.08-4.11h6Z", style "fill" "#1d1d1b" ] []
        , path [ d "M844,765.29a10.52,10.52,0,0,1-4.09-3.72,14.84,14.84,0,0,1-2.1-5.86v0h6v0a5.62,5.62,0,0,0,1.88,3.7,6.06,6.06,0,0,0,4.06,1.32,5.38,5.38,0,0,0,4.45-1.94,8.53,8.53,0,0,0,1.57-5.49v-3.63a8.47,8.47,0,0,0-1.57-5.46,5.41,5.41,0,0,0-4.45-1.94,5.57,5.57,0,0,0-3,.89,8.24,8.24,0,0,0-2.53,2.5h-5.47V722.87h21.78v5.77H844.73v9.73a8.38,8.38,0,0,1,2.5-1.43,8.06,8.06,0,0,1,2.82-.5,12.27,12.27,0,0,1,6.33,1.54,9.83,9.83,0,0,1,4,4.52,17.14,17.14,0,0,1,1.37,7.17v3.63a16.67,16.67,0,0,1-1.41,7.17,10.09,10.09,0,0,1-4.12,4.53,12.78,12.78,0,0,1-6.49,1.56A12.51,12.51,0,0,1,844,765.29Z", style "fill" "#1d1d1b" ] []
        -- 10
        , path [ d "M887.53,649h-6V612.4l-6.08,3.78V609.9l6.08-4.1h6Z", style "fill" "#1d1d1b" ] []
        , path [ d "M900.33,646.25q-3.11-3.24-3.1-9V617.55q0-5.84,3.12-9.06t9.08-3.23q6,0,9.1,3.22t3.1,9.07v19.66q0,5.82-3.12,9t-9.08,3.23Q903.43,649.49,900.33,646.25ZM914.12,642a7,7,0,0,0,1.51-4.83V617.55a7,7,0,0,0-1.5-4.84,7.41,7.41,0,0,0-9.4,0,7,7,0,0,0-1.5,4.84v19.66a7,7,0,0,0,1.51,4.83,7.39,7.39,0,0,0,9.38,0Z", style "fill" "#1d1d1b" ] []
        --- 6
        , path [ d "M913.53,518.18a9.92,9.92,0,0,1-4.07-4.46,16.35,16.35,0,0,1-1.4-7.07v0a24.62,24.62,0,0,1,.56-5.05,29,29,0,0,1,1.62-5.21c.11-.3.24-.59.38-.88s.27-.57.41-.84L920.32,476h6.47l-10.91,21.56,0-1.07a5.11,5.11,0,0,1,2.15-2.17,6.67,6.67,0,0,1,3.29-.77,10.41,10.41,0,0,1,5.7,1.51,9.5,9.5,0,0,1,3.62,4.42,17.81,17.81,0,0,1,1.23,7v0a16.53,16.53,0,0,1-1.4,7.14,9.93,9.93,0,0,1-4.08,4.52,14.26,14.26,0,0,1-12.89,0Zm10.83-6.09A7.52,7.52,0,0,0,925.9,507v0a8.7,8.7,0,0,0-1.61-5.61,5.62,5.62,0,0,0-4.62-2,4.84,4.84,0,0,0-4.14,2,9.33,9.33,0,0,0-1.47,5.62v0a7.48,7.48,0,0,0,1.54,5.07,6.28,6.28,0,0,0,8.76,0Z", style "fill" "#1d1d1b" ] []
        --- 13
        , path [ d "M888.23,389.48h-6V352.84l-6.09,3.78v-6.28l6.09-4.1h6Z", style "fill" "#1d1d1b" ] []
        , path [ d "M905.4,389.93l-2.73-1.33a10.82,10.82,0,0,1-4.4-3.83,13.91,13.91,0,0,1-2.1-6.06h6.11a6.65,6.65,0,0,0,1.15,3,5.39,5.39,0,0,0,2.28,1.77,8.6,8.6,0,0,0,3.27.58,6.35,6.35,0,0,0,4.62-1.61,6,6,0,0,0,1.65-4.52v-1.31a7.33,7.33,0,0,0-1.56-5,5.57,5.57,0,0,0-4.41-1.77h-3v-5.77h3a5,5,0,0,0,3.88-1.52,6.12,6.12,0,0,0,1.38-4.28V357a5.22,5.22,0,0,0-1.45-4,5.74,5.74,0,0,0-4.13-1.4,6.19,6.19,0,0,0-2.74.58,5.32,5.32,0,0,0-2,1.78,8.14,8.14,0,0,0-1.22,3h-6.09a16,16,0,0,1,2.22-6.06,10.9,10.9,0,0,1,4.13-3.84,12.24,12.24,0,0,1,5.74-1.31q5.52,0,8.55,2.94c2,2,3,4.73,3,8.3v.72a9.4,9.4,0,0,1-1.74,5.65,9.83,9.83,0,0,1-4.91,3.51,8.66,8.66,0,0,1,5.43,3.48,11.63,11.63,0,0,1,1.92,6.9V378a13.42,13.42,0,0,1-1.44,6.45,9.5,9.5,0,0,1-4.19,4.08,14.49,14.49,0,0,1-6.63,1.4Z", style "fill" "#1d1d1b" ] []
        --- 4
        , path [ d "M826.48,260.5l14.35-31.31H847l-14,31h21v5.62H826.48ZM844.91,247h5.85v25.46h-5.85Z", style "fill" "#1d1d1b" ] []
        --- 18
        , path [ d "M734.66,179.48h-6V142.84l-6.08,3.78v-6.28l6.08-4.1h6Z", style "fill" "#1d1d1b" ] []
        , path [ d "M750.06,178.44a10.75,10.75,0,0,1-4.54-4.21,12.19,12.19,0,0,1-1.6-6.32v-.71a12.27,12.27,0,0,1,1.6-6.1,10.82,10.82,0,0,1,4.28-4.31,9.39,9.39,0,0,1-3.63-3.61,9.84,9.84,0,0,1-1.37-5v-1a11.62,11.62,0,0,1,1.5-6,10.23,10.23,0,0,1,4.23-4,14.91,14.91,0,0,1,12.7,0,10.25,10.25,0,0,1,4.24,4,11.72,11.72,0,0,1,1.49,6v1a9.65,9.65,0,0,1-1.39,5,9.3,9.3,0,0,1-3.69,3.57,11.06,11.06,0,0,1,4.33,4.33,12,12,0,0,1,1.64,6.08v.71a12.2,12.2,0,0,1-1.61,6.32,10.7,10.7,0,0,1-4.54,4.21,16.35,16.35,0,0,1-13.64,0Zm10.5-5.17a6,6,0,0,0,2.45-2.34,6.76,6.76,0,0,0,.87-3.46v-.42a6.82,6.82,0,0,0-.87-3.49,6,6,0,0,0-2.45-2.34,8.55,8.55,0,0,0-7.35,0,6,6,0,0,0-2.46,2.35,7,7,0,0,0-.86,3.51v.45a6.79,6.79,0,0,0,.86,3.45,5.88,5.88,0,0,0,2.46,2.3,8.6,8.6,0,0,0,7.35,0Zm-.5-19.5a5.38,5.38,0,0,0,2.14-2.24,7.15,7.15,0,0,0,.77-3.36v-.42a6.57,6.57,0,0,0-.77-3.21,5.36,5.36,0,0,0-2.14-2.16,7,7,0,0,0-6.35,0,5.39,5.39,0,0,0-2.15,2.16,6.63,6.63,0,0,0-.76,3.24v.45a7,7,0,0,0,.76,3.31,5.44,5.44,0,0,0,2.15,2.23,6.78,6.78,0,0,0,6.35,0Z", style "fill" "#1d1d1b" ] []
        --- 1
        , path [ d "M634.52,119.82h-6V83.18L622.44,87V80.68l6.08-4.1h6Z", style "fill" "#1d1d1b" ] []
        ]


segment : GameState -> String -> String -> String -> Html msg
segment gameState fieldName color shape =
    path
        [ style "fill"
            (if gameState.lastHit == Just fieldName then
                "#29B6F6"

             else
                color
            )
        , d shape
        ]
        []


circleSegment : GameState -> String -> String -> String -> String -> String -> Html msg
circleSegment gameState fieldName color cx1 cy1 r1 =
    circle
        [ cx cx1
        , cy cy1
        , r r1
        , style "fill"
            (if gameState.lastHit == Just fieldName then
                "#29B6F6"

             else
                color
            )
        ]
        []
