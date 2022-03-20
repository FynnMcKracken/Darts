package darts.game

import darts.{AppState, spanNot}
import io.circe.generic.auto.*
import io.circe.syntax.*
import io.circe.{Encoder, Json}

import java.util.UUID


abstract class Game[Score: Encoder, Self <: Game[Score, Self]: Encoder] { self: Self =>
  val running: Boolean
  val lastHit: Option[Hit]
  val players: List[Player[Score]]

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

  def asJson: Json = Json.obj(
    (this.getClass.getSimpleName, summon[Encoder[Self]](this))
  )
}

object Game {
  def apply(gameMode: GameMode, players: List[AppState.PlayerCreation.Player]): Game[_, _] = Companion(gameMode)(players)

  abstract class Companion {
    type Score

    val initialScore: Score

    def apply(players: List[AppState.PlayerCreation.Player]): Game[Score, _] = {
      val players1: List[Player[Score]] = players.map(player => newPlayer(player.uuid, player.name))
      apply(running = true, lastHit = None, players = players1).advanceRound
    }

    def apply(running: Boolean, lastHit: Option[Hit], players: List[Player[Score]]): Game[Score, _]

    private def newPlayer(uuid: String, name: String): Player[Score] = Player[Score](
      uuid = uuid,
      name = name,
      score = initialScore,
      hits = List(),
      active = false,
      state = PlayerState.Normal
    )
  }

  object Companion {
    def apply(gameMode: GameMode): Companion = gameMode match {
      case GameMode.Standard => Standard
      case GameMode.Cricket => Cricket
    }
  }

  given Encoder[Game[_, _]] = (game: Game[_, _]) => game.asJson
}
