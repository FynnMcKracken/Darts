port module Lib exposing (..)

import Json.Encode as Encode


port sendMessage : String -> Cmd a


sendJsonMessage : Encode.Value -> Cmd a
sendJsonMessage value =
    sendMessage <| Encode.encode 0 value


type GameMode
    = Standard
    | Cricket


gameModeToString : GameMode -> String
gameModeToString gameMode =
    case gameMode of
        Standard ->
            "Standard"

        Cricket ->
            "Cricket"


encodeGameMode : GameMode -> Encode.Value
encodeGameMode gameMode =
    Encode.string <| gameModeToString gameMode


justOrNothing : Bool -> a -> Maybe a
justOrNothing condition value =
    if condition then
        Just value

    else
        Nothing


listFlatten : Maybe a -> List a -> List a
listFlatten value list =
    case value of
        Just val ->
            list ++ [ val ]

        Nothing ->
            []
