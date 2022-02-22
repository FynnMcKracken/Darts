package darts.game

import darts.game.Game.newPlayer
import darts.spanNot
import io.circe.generic.auto.*
import io.circe.syntax.*
import io.circe.{Encoder, Json}

import java.util.UUID


abstract class Game[Score: Encoder, Self <: Game[Score, Self]](val gameMode: GameMode) { self: Self =>
  val running: Boolean
  val lastHit: Option[Hit]
  val players: List[Player[Score]]

  val companion: Game.Companion[Score]

  def start: Self = this.copy(running = true, lastHit = None).advanceRound

  def advancePlayer: Self = {
    val (playersBeforeActive, activeAndFollowingPlayers) = players.spanNot(_.active)

    activeAndFollowingPlayers match {
      case activePlayer :: playersAfterActive =>
        val activePlayerState = if (activePlayer.state == PlayerState.FinishedRound) PlayerState.Normal else activePlayer.state
        val activePlayer1 = activePlayer.copy(active = false, state = activePlayerState)

        val (playersBeforeNext, nextAndFollowingPlayers) = playersAfterActive.spanNot(_.state != PlayerState.FinishedGame)

        nextAndFollowingPlayers match {
          case nextPlayer :: playersAfterNext =>
            val nextPlayer1 = nextPlayer.copy(active = true, hits = List())
            val players1 = playersBeforeActive :++ activePlayer1 +: playersBeforeNext :++ nextPlayer1 +: playersAfterNext
            this.copy(lastHit = None, players = players1)

          case Nil =>
            val players1 = playersBeforeActive :++ activePlayer1 +: playersAfterActive
            this.copy(players = players1).advanceRound
        }

      // no active player
      case Nil =>
        this
    }
  }

  def advanceRound: Self = {
    val (playersBeforeNext, nextAndFollowingPlayers) = players.spanNot(_.state != PlayerState.FinishedGame)

    val players1 = nextAndFollowingPlayers match {
      case nextPlayer :: followingPlayers =>
        val nextPlayer1 = nextPlayer.copy(active = true, hits = List())
        playersBeforeNext :++ nextPlayer1 +: followingPlayers

      // no next player
      case Nil =>
        players
    }

    this.copy(players = players1)
  }

  def addPlayer(name: String): Self = {
    val players1 = players :+ newPlayer(UUID.randomUUID().toString, name, companion.initialScore) // TODO wrap generating uuid in IO?
    this.copy(players = players1)
  }

  def removePlayer(uuid: String): Self = {
    val players1 = players.filterNot(_.uuid == uuid)
    this.copy(players = players1)
  }

  def processHit(hit: Hit): Self = {
    val (playersBeforeActive, activeAndFollowingPlayers) = players.spanNot(_.active)

    val players1 = activeAndFollowingPlayers match {
      case activePlayer :: playersAfterActive =>
        val activePlayer1 = if (activePlayer.state == PlayerState.Normal) processHitForPlayer(activePlayer, hit) else activePlayer

        playersBeforeActive :++ activePlayer1 +: playersAfterActive

      // no active player
      case Nil =>
        playersBeforeActive
    }

    this.copy(lastHit = Some(hit), players = players1)
  }

  protected def processHitForPlayer(player: Player[Score], hit: Hit): Player[Score]

  def copy(running: Boolean = running, lastHit: Option[Hit] = lastHit, players: List[Player[Score]] = players): Self

  def asJson: Json = EncoderOps(this).asJson(Game.encoder)
}

object Game {
  val initial: Game[_, _] = {
    val players = List(
      newPlayer(UUID.randomUUID().toString, "Hans, Only", Standard.initialScore),
      newPlayer(UUID.randomUUID().toString, "A", Standard.initialScore),
      newPlayer(UUID.randomUUID().toString, "B", Standard.initialScore),
      newPlayer(UUID.randomUUID().toString, "C", Standard.initialScore),
    )

    Game(GameMode.Standard, players)
  }

  def apply(gameMode: GameMode, players: List[Player[_]]): Game[_, _] = gameMode match {
    case GameMode.Standard =>
      val players1 = players.map(player => newPlayer(player.uuid, player.name, Standard.initialScore))
      Standard(running = false, lastHit = None, players1)

    case GameMode.Cricket =>
      val players1 = players.map(player => newPlayer(player.uuid, player.name, Cricket.initialScore))
      Cricket(running = false, lastHit = None, players1)
  }

  private def newPlayer[Score](uuid: String, name: String, score: Score): Player[Score] = Player[Score](
    uuid = uuid,
    name = name,
    score = score,
    hits = List(),
    active = false,
    state = PlayerState.Normal
  )

  abstract class Companion[Score] {
    val initialScore: Score
  }

  implicit def encoder[Score: Encoder, Self <: Game[Score, Self]]: Encoder[Game[Score, Self]] =
    Encoder.forProduct4("gameMode", "running", "lastHit", "players"){ (game: Game[Score, Self]) =>
      (game.gameMode, game.running, game.lastHit, game.players)
    }
}
