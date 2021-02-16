port module Main exposing (main)

import Browser exposing (Document)
import Html exposing (Html, button, div, h1, h5, input, main_, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (attribute, class, classList, disabled, id, placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Encode as Encode
import List
import Maybe
import String
import Svg exposing (circle, path, polyline, svg)
import Svg.Attributes exposing (cx, cy, d, height, points, r, viewBox, width)
import Json.Decode as Decode exposing (Decoder, Error)


main : Program () Model Msg
main =
  Browser.document {
    init = init,
    view = view,
    update = update,
    subscriptions = subscriptions
  }


-- PORTS

port sendMessage : String -> Cmd msg
port messageReceiver : (Decode.Value -> msg) -> Sub msg


-- MODEL

type alias Model = {
    gameRunning: Bool,
    lastHit: Maybe String,
    players: List Player,
    currentPlayer: Int,
    newPlayerName: String
  }

type alias Player = {
    name: String,
    score: Int,
    active: Bool,
    hits: List Int
  }

init : () -> (Model, Cmd Msg)
init _ = ({gameRunning = False, lastHit = Nothing, players = [], currentPlayer = 0, newPlayerName = ""}, Cmd.none)


-- UPDATE

type Msg
  = Recv (Result Error GameState) | StartGame | NextPlayer | NewPlayerNameChange String | AddNewPlayer | ResetScore | MissHit

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    (Recv (Ok state1)) -> (({ model | gameRunning = state1.running, lastHit = state1.lastHit, players = state1.players }), Cmd.none)
    (Recv (Err _)) -> (model, Cmd.none)
    StartGame -> (model, sendMessage (Encode.encode 0 (Encode.object[ ("startGame", Encode.null)])))
    NextPlayer -> (model, sendMessage (Encode.encode 0 (Encode.object[ ("nextPlayer", Encode.null)])))
    NewPlayerNameChange name -> ({model | newPlayerName = name}, Cmd.none)
    AddNewPlayer -> (({ model | newPlayerName = "" }), sendMessage (Encode.encode 0 (newPlayerEncode model.newPlayerName)))
    ResetScore -> (model, sendMessage (Encode.encode 0 (Encode.object[ ("resetScore", Encode.null)])))
    MissHit -> (model, sendMessage (Encode.encode 0 (Encode.object[ ("missHit", Encode.null)])))


newPlayerEncode : String -> Encode.Value
newPlayerEncode name =
    Encode.object [ ("newPlayer", Encode.string name) ]

-- SUBSCRIPTIONS

type alias GameState = {
    running: Bool,
    lastHit: Maybe String,
    players: List Player
  }

subscriptions : Model -> Sub Msg
subscriptions _ =
  messageReceiver (decodeSuggestions >> Recv)

decodeSuggestions : Decode.Value -> Result Error GameState
decodeSuggestions =
    Decode.decodeValue gameStateDecoder

gameStateDecoder : Decoder GameState
gameStateDecoder = Decode.map3 GameState
    (Decode.field "running" Decode.bool)
    (Decode.maybe (Decode.field "lastHit" Decode.string))
    (Decode.field "players" playersDecoder)

playersDecoder : Decoder (List Player)
playersDecoder =
    Decode.list (Decode.map4 Player
        (Decode.field "name" Decode.string)
        (Decode.field "score" Decode.int)
        (Decode.field "active" Decode.bool)
        (Decode.field "hits" (Decode.list Decode.int))
    )

-- VIEW

view : Model -> Document Msg
view model = {
    title = title model,
    body = body model
  }

title : Model -> String
title _ = "Dart"

renderHit : Int -> Html Msg
renderHit hit = div [ class "badge badge-pill hit-badge", classList[("badge-danger", hit == 0), ("badge-success", hit /= 0)]] [ text (String.fromInt(hit))]

renderRow : Player -> Html Msg
renderRow player =
    tr [ classList [("table-primary", player.active)] ]
        [ td [] [ text player.name ]
        , td [class "hits-cell"] ([] ++ (List.map renderHit player.hits))
        , td [] [ text (String.fromInt(player.score)) ]
        ]

body : Model -> List (Html Msg)
body model = [
    main_ [class "container"] [
      div [class "row mt-4"] [
        div [class "col"] [
          h1 [] [text "Dart"],
          div [] [text ("last hit: " ++ Maybe.withDefault "-" model.lastHit)]
        ]
      ],
      div [class "row mb-4"] [
        div [class "col"] [
          table [class "table table-bordered table-hover"] [
            thead [class "thead-light"] [
              tr [] [
                th [] [text "Player"],
                th [] [text "Hits"],
                th [] [text "Score"]
              ]
            ],
            tbody [] ([] ++ (List.map renderRow model.players))
          ]
        ]
      ],
      div [class "row mt-4"] [
        div [class "col"] [
          button [ class "btn btn-primary game-button", disabled (not model.gameRunning), onClick NextPlayer] [ text "Next player" ],
          button [ class "btn btn-outline-secondary game-button", disabled model.gameRunning, attribute "data-target" "#modal-new-player", attribute "data-toggle" "modal"] [ text "Add player" ]
        ],
        div [class "col text-center"] [
            button [ class "btn btn-success", disabled model.gameRunning, onClick StartGame] [ text "Start game" ]
        ],
        div [class "col text-right"] [
          button [ class "btn btn-outline-danger game-button", disabled (not model.gameRunning), attribute "data-target" "#modal-reset-score", attribute "data-toggle" "modal"] [ text "Reset game" ],
          button [ class "btn btn-danger", disabled (not model.gameRunning), onClick MissHit] [ text "Missed hit" ]
        ]
      ],
      div [class "row mb-2"] [
        div [class "col mb-2"] [
          dartBoard model
        ]
      ],
      div [class "modal fade", id "modal-new-player", attribute "role" "dialog"] [
        div [class "modal-dialog"] [
          div [class "modal-content"][
            div [class "modal-header"] [
              h5[] [text "New player"]
            ],
            div [class "modal-body"] [
            input [class "form-control", type_ "text", placeholder "Name", onInput NewPlayerNameChange, value model.newPlayerName] []
            ],
            div [class "modal-footer"] [
              button [ class "btn btn-secondary", attribute "data-dismiss" "modal"] [ text "Close" ],
              button [ class "btn btn-primary", attribute "data-dismiss" "modal", onClick AddNewPlayer] [ text "Add player" ]
            ]
          ]
        ]
      ],
      div [class "modal fade", id "modal-reset-score", attribute "role" "dialog"] [
              div [class "modal-dialog"] [
                div [class "modal-content"][
                  div [class "modal-header"] [
                    h5[] [text "Reset game"]
                  ],
                  div [class "modal-body"] [
                  text "Do you want to reset the current game?"
                  ],
                  div [class "modal-footer"] [
                    button [ class "btn btn-secondary", attribute "data-dismiss" "modal"] [ text "Close" ],
                    button [ class "btn btn-danger", attribute "data-dismiss" "modal", onClick ResetScore] [ text "Reset" ]
                  ]
                ]
              ]
            ]
    ]
  ]

dartBoard : Model -> Html msg
dartBoard model =
  svg [width "1000", height "1000", viewBox "0 0 1000 1000"] [
      segment model "12i" "#1d1d1b" "M411.48,326.28,479.57,459.9a44.9,44.9,0,0,0-11.38,8.29l-106-106A196,196,0,0,1,411.48,326.28Z",
      segment model "12o" "#1d1d1b" "M345.66,197.09l47.58,93.39a235.5,235.5,0,0,0-59.45,43.31L259.7,259.7A341.92,341.92,0,0,1,345.66,197.09Z",
      segment model "14o" "#1d1d1b" "M197.09,345.66l93.39,47.58a232.54,232.54,0,0,0-22.64,70L164.16,446.8A337.41,337.41,0,0,1,197.09,345.66Z",
      segment model "14i" "#1d1d1b" "M326.28,411.48l133.63,68.09A45.24,45.24,0,0,0,455.55,493L307.39,469.49A193.28,193.28,0,0,1,326.28,411.48Z",
      segment model "8i" "#1d1d1b" "M459.9,520.43,326.28,588.52a193.28,193.28,0,0,1-18.89-58L455.55,507A45,45,0,0,0,459.9,520.43Z",
      segment model "8o" "#1d1d1b" "M290.48,606.76l-93.39,47.58A337.41,337.41,0,0,1,164.16,553.2l103.68-16.43A232.54,232.54,0,0,0,290.48,606.76Z",
      segment model "7o" "#1d1d1b" "M393.24,709.52l-47.58,93.39a341.92,341.92,0,0,1-86-62.61l74.09-74.09A235.5,235.5,0,0,0,393.24,709.52Z",
      segment model "7i" "#1d1d1b" "M479.57,540.09,411.48,673.72a196,196,0,0,1-49.3-35.9l106-106A45.24,45.24,0,0,0,479.57,540.09Z",
      segment model "3i" "#1d1d1b" "M507,544.45l23.47,148.16a195.94,195.94,0,0,1-61,0L493,544.45A44.92,44.92,0,0,0,507,544.45Z",
      segment model "3o" "#1d1d1b" "M536.77,732.16,553.2,835.84a342.25,342.25,0,0,1-106.4,0l16.43-103.68a239.45,239.45,0,0,0,73.54,0Z",
      segment model "2o" "#1d1d1b" "M666.21,666.21,740.3,740.3a341.92,341.92,0,0,1-86,62.61l-47.58-93.39A235.5,235.5,0,0,0,666.21,666.21Z",
      segment model "2i" "#1d1d1b" "M531.81,531.81l106,106a196,196,0,0,1-49.3,35.9L520.43,540.1A44.9,44.9,0,0,0,531.81,531.81Z",
      segment model "10o" "#1d1d1b" "M732.16,536.77,835.84,553.2a337.41,337.41,0,0,1-32.93,101.14l-93.39-47.58A232.54,232.54,0,0,0,732.16,536.77Z",
      segment model "10i" "#1d1d1b" "M544.45,507l148.16,23.47a193.28,193.28,0,0,1-18.89,58L540.09,520.43A45.24,45.24,0,0,0,544.45,507Z",
      segment model "13i" "#1d1d1b" "M692.61,469.49,544.45,493a45,45,0,0,0-4.35-13.39l133.62-68.09A193.28,193.28,0,0,1,692.61,469.49Z",
      segment model "13o" "#1d1d1b" "M835.84,446.8,732.16,463.23a232.54,232.54,0,0,0-22.64-70l93.39-47.58A337.41,337.41,0,0,1,835.84,446.8Z",
      segment model "18o" "#1d1d1b" "M740.3,259.7l-74.09,74.09a235.5,235.5,0,0,0-59.45-43.31l47.58-93.39A341.92,341.92,0,0,1,740.3,259.7Z",
      segment model "18i" "#1d1d1b" "M637.82,362.18l-106,106a45.24,45.24,0,0,0-11.38-8.28l68.09-133.63A196,196,0,0,1,637.82,362.18Z",
      segment model "20i" "#1d1d1b" "M530.51,307.39,507,455.55a44.92,44.92,0,0,0-14.08,0L469.49,307.39a195.94,195.94,0,0,1,61,0Z",
      segment model "20o" "#1d1d1b" "M553.2,164.16,536.77,267.84a239.45,239.45,0,0,0-73.54,0L446.8,164.16a342.25,342.25,0,0,1,106.4,0Z",
      segment model "5o" "#fff" "M446.8,164.16l16.43,103.68a232.54,232.54,0,0,0-70,22.64l-47.58-93.39A337.41,337.41,0,0,1,446.8,164.16Z",
      segment model "5i" "#fff" "M469.49,307.39,493,455.55a45,45,0,0,0-13.39,4.35L411.48,326.28A193.28,193.28,0,0,1,469.49,307.39Z",
      segment model "9i" "#fff" "M362.18,362.18l106,106a45.24,45.24,0,0,0-8.28,11.38L326.28,411.48A196,196,0,0,1,362.18,362.18Z",
      segment model "9o" "#fff" "M259.7,259.7l74.09,74.09a235.5,235.5,0,0,0-43.31,59.45l-93.39-47.58A341.92,341.92,0,0,1,259.7,259.7Z",
      segment model "11o" "#fff" "M164.16,446.8l103.68,16.43a239.45,239.45,0,0,0,0,73.54L164.16,553.2a342.25,342.25,0,0,1,0-106.4Z",
      segment model "11i" "#fff" "M307.39,469.49,455.55,493a44.92,44.92,0,0,0,0,14.08L307.39,530.51a195.94,195.94,0,0,1,0-61Z",
      segment model "16o" "#fff" "M333.79,666.21,259.7,740.3a341.92,341.92,0,0,1-62.61-86l93.39-47.58A235.5,235.5,0,0,0,333.79,666.21Z",
      segment model "16i" "#fff" "M468.19,531.81l-106,106a196,196,0,0,1-35.9-49.3L459.9,520.43A44.9,44.9,0,0,0,468.19,531.81Z",
      segment model "19o" "#fff" "M463.23,732.16,446.8,835.84a337.41,337.41,0,0,1-101.14-32.93l47.58-93.39A232.54,232.54,0,0,0,463.23,732.16Z",
      segment model "19i" "#fff" "M493,544.45,469.49,692.61a193.28,193.28,0,0,1-58-18.89l68.09-133.63A45.24,45.24,0,0,0,493,544.45Z",
      segment model "17i" "#fff" "M520.43,540.1l68.09,133.62a193.28,193.28,0,0,1-58,18.89L507,544.45A45,45,0,0,0,520.43,540.1Z",
      segment model "17o" "#fff" "M606.76,709.52l47.58,93.39A337.41,337.41,0,0,1,553.2,835.84L536.77,732.16A232.54,232.54,0,0,0,606.76,709.52Z",
      segment model "15o" "#fff" "M709.52,606.76l93.39,47.58a341.92,341.92,0,0,1-62.61,86l-74.09-74.09A235.5,235.5,0,0,0,709.52,606.76Z",
      segment model "15i" "#fff" "M540.09,520.43l133.63,68.09a196,196,0,0,1-35.9,49.3l-106-106A45.24,45.24,0,0,0,540.09,520.43Z",
      segment model "6i" "#fff" "M692.61,469.49a195.94,195.94,0,0,1,0,61L544.45,507a44.92,44.92,0,0,0,0-14.08Z",
      segment model "6o" "#fff" "M835.84,446.8a342.25,342.25,0,0,1,0,106.4L732.16,536.77a239.45,239.45,0,0,0,0-73.54Z",
      segment model "4i" "#fff" "M673.72,411.48,540.1,479.57a44.9,44.9,0,0,0-8.29-11.38l106-106A196,196,0,0,1,673.72,411.48Z",
      segment model "4o" "#fff" "M802.91,345.66l-93.39,47.58a235.5,235.5,0,0,0-43.31-59.45L740.3,259.7A341.92,341.92,0,0,1,802.91,345.66Z",
      segment model "6x2" "#4daf50" "M875.4,440.54a386.59,386.59,0,0,1,0,118.92h-.08l-39.48-6.25a342.25,342.25,0,0,0,0-106.4l39.48-6.25Z",
      segment model "13x2" "#e95226" "M875.4,440.54h-.08l-39.48,6.25a337.41,337.41,0,0,0-32.93-101.14l35.67-18.18.13-.06q6.13,12,11.44,24.6A375.88,375.88,0,0,1,875.4,440.54Z",
      segment model "10x2" "#e95226" "M875.32,559.45h.08A375.88,375.88,0,0,1,850.15,648q-5.29,12.54-11.44,24.6l-.13-.06-35.67-18.18A337.41,337.41,0,0,0,835.84,553.2Z",
      segment model "4x2" "#4daf50" "M838.71,327.42l-.13.06-35.67,18.18a341.92,341.92,0,0,0-62.61-86l28.4-28.4.06-.06A378.45,378.45,0,0,1,838.71,327.42Z",
      segment model "15x2" "#4daf50" "M838.58,672.52l.13.06a378.45,378.45,0,0,1-70,96.18l-.06-.06-28.4-28.4a341.92,341.92,0,0,0,62.61-86Z",
      segment model "18x2" "#e95226" "M768.76,231.24l-.06.06-28.4,28.4a341.92,341.92,0,0,0-86-62.61l18.18-35.67.06-.13A378.45,378.45,0,0,1,768.76,231.24Z",
      segment model "2x2" "#e95226" "M768.7,768.7l.06.06a378.45,378.45,0,0,1-96.18,70l-.06-.13-18.18-35.67a341.92,341.92,0,0,0,86-62.61Z",
      segment model "6x3" "#4daf50" "M732.16,463.23a239.45,239.45,0,0,1,0,73.54l-39.55-6.26a195.94,195.94,0,0,0,0-61Z",
      segment model "13x3" "#e95226" "M732.16,463.23l-39.55,6.26a193.28,193.28,0,0,0-18.89-58l35.8-18.24A232.54,232.54,0,0,1,732.16,463.23Z",
      segment model "10x3" "#e95226" "M692.61,530.51l39.55,6.26a232.54,232.54,0,0,1-22.64,70l-35.8-18.24A193.28,193.28,0,0,0,692.61,530.51Z",
      segment model "4x3" "#4daf50" "M709.52,393.24l-35.8,18.24a196,196,0,0,0-35.9-49.3l28.39-28.39A235.5,235.5,0,0,1,709.52,393.24Z",
      segment model "15x3" "#4daf50" "M673.72,588.52l35.8,18.24a235.5,235.5,0,0,1-43.31,59.45l-28.39-28.39A196,196,0,0,0,673.72,588.52Z",
      segment model "1x2" "#4daf50" "M672.58,161.29l-.06.13-18.18,35.67A337.41,337.41,0,0,0,553.2,164.16l6.25-39.48v-.08A375.88,375.88,0,0,1,648,149.85Q660.52,155.14,672.58,161.29Z",
      segment model "17x2" "#4daf50" "M672.52,838.58l.06.13q-12,6.13-24.6,11.44a375.88,375.88,0,0,1-88.52,25.25v-.08l-6.25-39.48a337.41,337.41,0,0,0,101.14-32.93Z",
      segment model "18x3" "#e95226" "M666.21,333.79l-28.39,28.39a196,196,0,0,0-49.3-35.9l18.24-35.8A235.5,235.5,0,0,1,666.21,333.79Z",
      segment model "2x3" "#e95226" "M637.82,637.82l28.39,28.39a235.5,235.5,0,0,1-59.45,43.31l-18.24-35.8A196,196,0,0,0,637.82,637.82Z",
      segment model "1o" "#fff" "M654.34,197.09l-47.58,93.39a232.54,232.54,0,0,0-70-22.64L553.2,164.16A337.41,337.41,0,0,1,654.34,197.09Z",
      segment model "1x3" "#4daf50" "M606.76,290.48l-18.24,35.8a193.28,193.28,0,0,0-58-18.89l6.26-39.55A232.54,232.54,0,0,1,606.76,290.48Z",
      segment model "17x3" "#4daf50" "M588.52,673.72l18.24,35.8a232.54,232.54,0,0,1-70,22.64l-6.26-39.55A193.28,193.28,0,0,0,588.52,673.72Z",
      segment model "1i" "#fff" "M588.52,326.28,520.43,459.91A45.24,45.24,0,0,0,507,455.55l23.47-148.16A193.28,193.28,0,0,1,588.52,326.28Z",
      segment model "3x2" "#e95226" "M559.45,875.32v.08a386.59,386.59,0,0,1-118.92,0v-.08l6.25-39.48a342.25,342.25,0,0,0,106.4,0Z",
      segment model "20x2" "#e95226" "M559.46,124.6v.08l-6.25,39.48a342.25,342.25,0,0,0-106.4,0l-6.25-39.48v-.08a386.59,386.59,0,0,1,118.92,0Z",
      segment model "Bullseye" "#4daf50" "M544.45,493a44.82,44.82,0,1,1-4.35-13.39A44.92,44.92,0,0,1,544.45,493ZM520,500a20,20,0,1,0-20,20A20,20,0,0,0,520,500Z",
      segment model "3x3" "#e95226" "M530.51,692.61l6.26,39.55a239.45,239.45,0,0,1-73.54,0l6.26-39.55a195.94,195.94,0,0,0,61,0Z",
      segment model "20x3" "#e95226" "M536.77,267.84l-6.26,39.55a195.94,195.94,0,0,0-61,0l-6.26-39.55a239.45,239.45,0,0,1,73.54,0Z",
      segment model "19x3" "#4daf50" "M469.49,692.61l-6.26,39.55a232.54,232.54,0,0,1-70-22.64l18.24-35.8A193.28,193.28,0,0,0,469.49,692.61Z",
      segment model "5x3" "#4daf50" "M463.23,267.84l6.26,39.55a193.28,193.28,0,0,0-58,18.89l-18.24-35.8A232.54,232.54,0,0,1,463.23,267.84Z",
      segment model "19x2" "#4daf50" "M446.8,835.84l-6.25,39.48v.08A375.88,375.88,0,0,1,352,850.15q-12.54-5.29-24.6-11.44l.06-.13,18.18-35.67A337.41,337.41,0,0,0,446.8,835.84Z",
      segment model "5x2" "#4daf50" "M440.55,124.68l6.25,39.48a337.41,337.41,0,0,0-101.14,32.93l-18.18-35.67-.06-.13q12-6.14,24.6-11.44a375.88,375.88,0,0,1,88.52-25.25Z",
      segment model "12x3" "#e95226" "M393.24,290.48l18.24,35.8a196,196,0,0,0-49.3,35.9l-28.39-28.39A235.5,235.5,0,0,1,393.24,290.48Z",
      segment model "7x3" "#e95226" "M411.48,673.72l-18.24,35.8a235.5,235.5,0,0,1-59.45-43.31l28.39-28.39A196,196,0,0,0,411.48,673.72Z",
      segment model "16x3" "#4daf50" "M362.18,637.82l-28.39,28.39a235.5,235.5,0,0,1-43.31-59.45l35.8-18.24A196,196,0,0,0,362.18,637.82Z",
      segment model "9x3" "#4daf50" "M333.79,333.79l28.39,28.39a196,196,0,0,0-35.9,49.3l-35.8-18.24A235.5,235.5,0,0,1,333.79,333.79Z",
      segment model "12x2" "#e95226" "M327.48,161.42l18.18,35.67a341.92,341.92,0,0,0-86,62.61l-28.4-28.4-.06-.06a378.45,378.45,0,0,1,96.18-70Z",
      segment model "7x2" "#e95226" "M345.66,802.91l-18.18,35.67-.06.13a378.45,378.45,0,0,1-96.18-70l.06-.06,28.4-28.4A341.92,341.92,0,0,0,345.66,802.91Z",
      segment model "14x3" "#e95226" "M290.48,393.24l35.8,18.24a193.28,193.28,0,0,0-18.89,58l-39.55-6.26A232.54,232.54,0,0,1,290.48,393.24Z",
      segment model "8x3" "#e95226" "M326.28,588.52l-35.8,18.24a232.54,232.54,0,0,1-22.64-70l39.55-6.26A193.28,193.28,0,0,0,326.28,588.52Z",
      segment model "11x3" "#4daf50" "M267.84,463.23l39.55,6.26a195.94,195.94,0,0,0,0,61l-39.55,6.26a239.45,239.45,0,0,1,0-73.54Z",
      segment model "16x2" "#4daf50" "M259.7,740.3l-28.4,28.4-.06.06a378.45,378.45,0,0,1-70-96.18l.13-.06,35.67-18.18A341.92,341.92,0,0,0,259.7,740.3Z",
      segment model "9x2" "#4daf50" "M231.3,231.3l28.4,28.4a341.92,341.92,0,0,0-62.61,86l-35.67-18.18-.13-.06a378.45,378.45,0,0,1,70-96.18Z",
      segment model "14x2" "#e95226" "M161.42,327.48l35.67,18.18A337.41,337.41,0,0,0,164.16,446.8l-39.48-6.25h-.08A375.88,375.88,0,0,1,149.85,352q5.29-12.54,11.44-24.6Z",
      segment model "8x2" "#e95226" "M197.09,654.34l-35.67,18.18-.13.06q-6.14-12-11.44-24.6a375.88,375.88,0,0,1-25.25-88.52h.08l39.48-6.25A337.41,337.41,0,0,0,197.09,654.34Z",
      segment model "11x2" "#4daf50" "M124.68,440.55l39.48,6.25a342.25,342.25,0,0,0,0,106.4l-39.48,6.25h-.08a386.59,386.59,0,0,1,0-118.92Z",
      circleSegment model "Bullseyex2" "#e95226" "500" "500" "20",
      path [d "M536.77,732.16a239.45,239.45,0,0,1-73.54,0,232.54,232.54,0,0,1-70-22.64A237,237,0,0,1,290.48,606.76a232.54,232.54,0,0,1-22.64-70,239.45,239.45,0,0,1,0-73.54,232.54,232.54,0,0,1,22.64-70A237,237,0,0,1,393.24,290.48a232.54,232.54,0,0,1,70-22.64,239.45,239.45,0,0,1,73.54,0,232.54,232.54,0,0,1,70,22.64A237,237,0,0,1,709.52,393.24a232.54,232.54,0,0,1,22.64,70,239.45,239.45,0,0,1,0,73.54,232.54,232.54,0,0,1-22.64,70A237,237,0,0,1,606.76,709.52,232.54,232.54,0,0,1,536.77,732.16Z", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M530.51,307.39a194.69,194.69,0,1,0,58,18.89A194.25,194.25,0,0,0,530.51,307.39Z", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M559.46,875.4a386.59,386.59,0,0,1-118.92,0A375.88,375.88,0,0,1,352,850.15q-12.54-5.29-24.6-11.44A381.28,381.28,0,0,1,161.29,672.58q-6.14-12-11.44-24.6a375.88,375.88,0,0,1-25.25-88.52,386.59,386.59,0,0,1,0-118.92A375.88,375.88,0,0,1,149.85,352q5.29-12.54,11.44-24.6A381.28,381.28,0,0,1,327.42,161.29q12-6.14,24.6-11.44a375.88,375.88,0,0,1,88.52-25.25,386.59,386.59,0,0,1,118.92,0A375.88,375.88,0,0,1,648,149.85q12.54,5.29,24.6,11.44A381.28,381.28,0,0,1,838.71,327.42q6.13,12,11.44,24.6a375.88,375.88,0,0,1,25.25,88.52,386.59,386.59,0,0,1,0,118.92A375.88,375.88,0,0,1,850.15,648q-5.29,12.54-11.44,24.6A381.28,381.28,0,0,1,672.58,838.71q-12,6.13-24.6,11.44A375.88,375.88,0,0,1,559.46,875.4Z", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M553.2,164.16a339.31,339.31,0,1,0,101.14,32.93A340.7,340.7,0,0,0,553.2,164.16Z", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "559.45 875.32 553.2 835.84 536.77 732.16 530.51 692.61 507.04 544.45", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "520.43 540.1 588.52 673.72 606.76 709.52 654.34 802.91 672.52 838.58", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "531.81 531.81 637.82 637.82 666.21 666.21 740.3 740.3 768.7 768.7", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "540.09 520.43 673.72 588.52 709.52 606.76 802.91 654.34 838.58 672.52", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "544.45 507.04 692.61 530.51 732.16 536.77 835.84 553.2 875.32 559.45", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "875.32 440.55 835.84 446.8 732.16 463.23 692.61 469.49 544.45 492.96", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "838.58 327.48 802.91 345.66 709.52 393.24 673.72 411.48 540.1 479.57", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "768.7 231.3 740.3 259.7 666.21 333.79 637.82 362.18 531.81 468.19", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "672.52 161.42 654.34 197.09 606.76 290.48 588.52 326.28 520.43 459.91", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "559.45 124.68 553.2 164.16 536.77 267.84 530.51 307.39 507.04 455.55", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "440.55 124.68 446.8 164.16 463.23 267.84 469.49 307.39 492.96 455.55", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "479.57 459.9 411.48 326.28 393.24 290.48 345.66 197.09 327.48 161.42", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "468.19 468.19 362.18 362.18 333.79 333.79 259.7 259.7 231.3 231.3", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "459.91 479.57 326.28 411.48 290.48 393.24 197.09 345.66 161.42 327.48", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "124.68 440.55 164.16 446.8 267.84 463.23 307.39 469.49 455.55 492.96", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "455.55 507.04 307.39 530.51 267.84 536.77 164.16 553.2 124.68 559.45", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "459.9 520.43 326.28 588.52 290.48 606.76 197.09 654.34 161.42 672.52", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "468.19 531.81 362.18 637.82 333.79 666.21 259.7 740.3 231.3 768.7", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "479.57 540.09 411.48 673.72 393.24 709.52 345.66 802.91 327.48 838.58", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      polyline [points "492.96 544.45 469.49 692.61 463.23 732.16 446.8 835.84 440.55 875.32", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M520.43,540.1A45,45,0,0,1,507,544.45", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M479.57,540.09A45.24,45.24,0,0,0,493,544.45", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M479.57,540.09a45.24,45.24,0,0,1-11.38-8.28", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M493,544.45a44.92,44.92,0,0,0,14.08,0", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M455.55,507a45,45,0,0,0,4.35,13.39", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M459.9,520.43a44.9,44.9,0,0,0,8.29,11.38", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M531.81,531.81a44.9,44.9,0,0,1-11.38,8.29", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M531.81,468.19a44.9,44.9,0,0,1,8.29,11.38", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M468.19,468.19a44.9,44.9,0,0,1,11.38-8.29", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M479.57,459.9A45,45,0,0,1,493,455.55", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M520.43,459.91a45.24,45.24,0,0,1,11.38,8.28", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M507,455.55a45.24,45.24,0,0,1,13.39,4.36", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M459.91,479.57a45.24,45.24,0,0,1,8.28-11.38", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M540.09,520.43a45.24,45.24,0,0,1-8.28,11.38", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M455.55,507a44.92,44.92,0,0,1,0-14.08", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M544.45,507a45.24,45.24,0,0,1-4.36,13.39", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M544.45,493a44.92,44.92,0,0,1,0,14.08", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M455.55,493a45.24,45.24,0,0,1,4.36-13.39", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M507,455.55a44.92,44.92,0,0,0-14.08,0", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      path [d "M540.1,479.57A45,45,0,0,1,544.45,493", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] [],
      circle [cx "500", cy "500", r "20", style "fill" "none", style "stroke" "#1d1d1b", style "stroke-miterlimit" "10", style "stroke-width" "5px"] []
  ]

segment : Model -> String -> String -> String -> Html msg
segment model fieldName color shape = path [style "fill" (if model.lastHit == Just fieldName then "#29B6F6" else color), d shape] []

circleSegment : Model -> String -> String -> String -> String -> String -> Html msg
circleSegment model fieldName color cx1 cy1 r1 = circle [cx cx1, cy cy1, r r1, style "fill" (if model.lastHit == Just fieldName then "#29B6F6" else color)] []
