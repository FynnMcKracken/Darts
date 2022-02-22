package darts

import darts.game.GameMode


enum ClientMessage:
  case StartGame
  case ResetGame
  case NextPlayer
  case MissHit
  case AddPlayer(name: String)
  case RemovePlayer(uuid: String)
  case ChangeGameMode(gameMode: GameMode)
