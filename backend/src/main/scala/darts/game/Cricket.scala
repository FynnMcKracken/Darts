package darts.game

import darts.game.Cricket.Score
import io.circe.generic.auto.*


case class Cricket(
  running: Boolean,
  lastHit: Option[Hit],
  players: List[Player[Score]]
) extends Game[Score, Cricket](GameMode.Cricket) {
  override val companion: Game.Companion[Score] = Cricket

  override protected def processHitForPlayer(player: Player[Score], hit: Hit): Player[Score] = {
    val hits = player.hits :+ hit

    val score = hit.value match {
      case 15 => addToScore(player.score, _.`15`, (score, value) => score.copy(`15` = value), hit)
      case 16 => addToScore(player.score, _.`16`, (score, value) => score.copy(`16` = value), hit)
      case 17 => addToScore(player.score, _.`17`, (score, value) => score.copy(`17` = value), hit)
      case 18 => addToScore(player.score, _.`18`, (score, value) => score.copy(`18` = value), hit)
      case 19 => addToScore(player.score, _.`19`, (score, value) => score.copy(`19` = value), hit)
      case 20 => addToScore(player.score, _.`20`, (score, value) => score.copy(`20` = value), hit)
      case 25 => addToScore(player.score, _.`25`, (score, value) => score.copy(`25` = value), hit)
      case _ => player.score
    }

    val state = if (finishedGame(score)) PlayerState.FinishedGame else if (hits.length >= 3) PlayerState.FinishedRound else PlayerState.Normal

    player.copy(hits = hits, score = score, state = state)
  }

  // TODO implement points
  private def addToScore(score: Score, getter: Score => Int, setter: (Score, Int) => Score, hit: Hit): Score = {
    val newValue = getter(score) + hit.multiplier
    val newValue1 = if (newValue > 3) 3 else newValue
    setter(score, newValue1)
  }

  private def finishedGame(score: Score): Boolean =
    score.`15` == 3 &&
    score.`16` == 3 &&
    score.`17` == 3 &&
    score.`18` == 3 &&
    score.`19` == 3 &&
    score.`20` == 3 &&
    score.`25` == 3
}

object Cricket extends Game.Companion[Score] {
  case class Score(
    points: Int,
    `15`: Int,
    `16`: Int,
    `17`: Int,
    `18`: Int,
    `19`: Int,
    `20`: Int,
    `25`: Int,
  )

  val initialScore: Score = Score(0, 0, 0, 0, 0, 0 ,0, 0)
}
