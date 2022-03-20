package darts

import darts.game.GameMode


enum ClientMessage:
  case AddPlayer(name: String)
  case RemovePlayer(uuid: String)
  case NewGame
  case StartGame(gameMode: GameMode)
  case ResetGame
  case NextPlayer
  case MissHit
  case ChangeGameMode(gameMode: GameMode)
