package darts

import cats.effect.{IO, Sync}
import cats.implicits.*
import darts.game.{GameMode, Hit}
import io.circe.generic.auto.*
import io.circe.parser.decode
import io.circe.syntax.*
import io.circe.{Decoder, Encoder, Json}
import org.typelevel.log4cats.Logger
import org.typelevel.log4cats.slf4j.Slf4jLogger

import java.util.UUID
import scala.deriving.Mirror


sealed abstract class AppState[ClientMessage: Decoder] {
  def processHit(hit: Hit): Option[AppState[_]] = this match {
    case game: AppState.Game => Some(game.copy(game = game.game.processHit(hit)))
    case _ => None
  }

  def processClientMessage(message: String): IO[Option[AppState[_]]] = decode[ClientMessage](message) match {
    case Right(message1) => Logger[IO].debug(s"message received: $message").as(Some(this.processClientMessage1(message1)))
    case Left(_) => Logger[IO].warn(s"invalid message for state ${this.getClass.getSimpleName} received: $message").as(None)
  }

  def processClientMessage1(message: ClientMessage): AppState[_]

  private given[F[_]: Sync]: Logger[F] = Slf4jLogger.getLogger[F]
}

object AppState {
  val initial: AppState[_] = {
    val players = List(
      PlayerCreation.Player(UUID.randomUUID().toString, "Hans, Only"),
      PlayerCreation.Player(UUID.randomUUID().toString, "A"),
      PlayerCreation.Player(UUID.randomUUID().toString, "B"),
      PlayerCreation.Player(UUID.randomUUID().toString, "C"),
    )

    PlayerCreation(players)
  }


  // ---- Player Creation ----

  case class PlayerCreation(players: List[PlayerCreation.Player]) extends AppState[PlayerCreation.ClientMessage] {
    import darts.AppState.PlayerCreation.ClientMessage
    override def processClientMessage1(message: ClientMessage): AppState[_] = message match {
      case ClientMessage.AddPlayer(name) => copy(players = players :+ PlayerCreation.Player(uuid = UUID.randomUUID().toString, name = name))
      case ClientMessage.RemovePlayer(uuid) => copy(players = players.filterNot(_.uuid == uuid))
      case ClientMessage.NewGame => GameSelection(players)
    }
  }

  object PlayerCreation {
    enum ClientMessage:
      case AddPlayer(name: String)
      case RemovePlayer(uuid: String)
      case NewGame

    case class Player(uuid: String, name: String)
  }


  // ---- Game Selection ----

  case class GameSelection(players: List[PlayerCreation.Player]) extends AppState[GameSelection.ClientMessage] {
    import darts.AppState.GameSelection.ClientMessage
    override def processClientMessage1(message: ClientMessage): AppState[_] = message match {
      case ClientMessage.StartGame(gameMode) => Game(game.Game(gameMode, players))
    }
  }

  object GameSelection {
    enum ClientMessage:
      case StartGame(gameMode: GameMode)
  }


  // ---- Game ----

  case class Game(game: darts.game.Game[_, _]) extends AppState[Game.ClientMessage] {
    import darts.AppState.Game.ClientMessage
    override def processClientMessage1(message: ClientMessage): AppState[_] = message match {
      case ClientMessage.NextPlayer => copy(game = game.advancePlayer)
      case ClientMessage.MissHit => copy(game = game.processHit(Hit.Miss))
      case ClientMessage.CloseGame => PlayerCreation(game.players.map(player => PlayerCreation.Player(player.uuid, player.name)))
    }
  }

  object Game {
    enum ClientMessage:
      case NextPlayer
      case MissHit
      case CloseGame
  }
}
