package darts.game

import io.circe.generic.auto.*
import Standard.Score


case class Standard(
  running: Boolean,
  lastHit: Option[Hit],
  players: List[Player[Score]]
) extends Game[Score, Standard](GameMode.Standard) {
  override val companion: Game.Companion.Aux[Score] = Standard

  override protected def processHitForPlayer(player: Player[Score], hit: Hit): Player[Score] = {
    val hits = player.hits :+ hit
    val score = Score(player.score.points - hit.points)

    val score1 = if (score.points < 0) Score(score.points + hits.map(_.points).sum) else score

    val state = if (score1.points == 0) PlayerState.FinishedGame else if (hits.length >= 3) PlayerState.FinishedRound else PlayerState.Normal

    player.copy(hits = hits, score = score1, state = state)
  }
}

object Standard extends Game.Companion {
  case class Score(points: Int)

  val initialScore: Score = Score(501)
}
