package darts.game

import io.circe.generic.auto.*
import io.circe.parser.decode
import io.circe.syntax.*
import io.circe.{Decoder, Encoder, Json}

import java.util.UUID
import scala.util.Try


enum GameMode:
  case Standard
  case Cricket

object GameMode:
  given Decoder[GameMode] = Decoder.decodeString.emapTry(s => Try(GameMode.valueOf(s)))


case class Player[Score](
  uuid: String,
  name: String,
  score: Score,
  hits: List[Hit],
  active: Boolean,
  state: PlayerState
)


enum PlayerState:
  case Normal
  case FinishedRound
  case FinishedGame

object PlayerState:
  given Encoder[PlayerState] = Encoder.encodeString.contramap(_.toString)


enum Hit(val value: Int, val multiplier: Int):

  def points: Int = value * multiplier

  case Miss extends Hit(0, 1)

  case `1o` extends Hit(1, 1)
  case `1i` extends Hit(1, 1)
  case `1x2` extends Hit(1, 2)
  case `1x3` extends Hit(1, 3)

  case `2o` extends Hit(2, 1)
  case `2i` extends Hit(2, 1)
  case `2x2` extends Hit(2, 2)
  case `2x3` extends Hit(2, 3)

  case `3o` extends Hit(3, 1)
  case `3i` extends Hit(3, 1)
  case `3x2` extends Hit(3, 2)
  case `3x3` extends Hit(3, 3)

  case `4o` extends Hit(4, 1)
  case `4i` extends Hit(4, 1)
  case `4x2` extends Hit(4, 2)
  case `4x3` extends Hit(4, 3)

  case `5o` extends Hit(5, 1)
  case `5i` extends Hit(5, 1)
  case `5x2` extends Hit(5, 2)
  case `5x3` extends Hit(5, 3)

  case `6o` extends Hit(6, 1)
  case `6i` extends Hit(6, 1)
  case `6x2` extends Hit(6, 2)
  case `6x3` extends Hit(6, 3)

  case `7o` extends Hit(7, 1)
  case `7i` extends Hit(7, 1)
  case `7x2` extends Hit(7, 2)
  case `7x3` extends Hit(7, 3)

  case `8o` extends Hit(8, 1)
  case `8i` extends Hit(8, 1)
  case `8x2` extends Hit(8, 2)
  case `8x3` extends Hit(8, 3)

  case `9o` extends Hit(9, 1)
  case `9i` extends Hit(9, 1)
  case `9x2` extends Hit(9, 2)
  case `9x3` extends Hit(9, 3)

  case `10o` extends Hit(10, 1)
  case `10i` extends Hit(10, 1)
  case `10x2` extends Hit(10, 2)
  case `10x3` extends Hit(10, 3)

  case `11o` extends Hit(11, 1)
  case `11i` extends Hit(11, 1)
  case `11x2` extends Hit(11, 2)
  case `11x3` extends Hit(11, 3)

  case `12o` extends Hit(12, 1)
  case `12i` extends Hit(12, 1)
  case `12x2` extends Hit(12, 2)
  case `12x3` extends Hit(12, 3)

  case `13o` extends Hit(13, 1)
  case `13i` extends Hit(13, 1)
  case `13x2` extends Hit(13, 2)
  case `13x3` extends Hit(13, 3)

  case `14o` extends Hit(14, 1)
  case `14i` extends Hit(14, 1)
  case `14x2` extends Hit(14, 2)
  case `14x3` extends Hit(14, 3)

  case `15o` extends Hit(15, 1)
  case `15i` extends Hit(15, 1)
  case `15x2` extends Hit(15, 2)
  case `15x3` extends Hit(15, 3)

  case `16o` extends Hit(16, 1)
  case `16i` extends Hit(16, 1)
  case `16x2` extends Hit(16, 2)
  case `16x3` extends Hit(16, 3)

  case `17o` extends Hit(17, 1)
  case `17i` extends Hit(17, 1)
  case `17x2` extends Hit(17, 2)
  case `17x3` extends Hit(17, 3)

  case `18o` extends Hit(18, 1)
  case `18i` extends Hit(18, 1)
  case `18x2` extends Hit(18, 2)
  case `18x3` extends Hit(18, 3)

  case `19o` extends Hit(19, 1)
  case `19i` extends Hit(19, 1)
  case `19x2` extends Hit(19, 2)
  case `19x3` extends Hit(19, 3)

  case `20o` extends Hit(20, 1)
  case `20i` extends Hit(20, 1)
  case `20x2` extends Hit(20, 2)
  case `20x3` extends Hit(20, 3)

  case `Bullseye` extends Hit(25, 1)
  case `Bullseyex2` extends Hit(25, 2)

object Hit:
  given Encoder[Hit] = Encoder.encodeString.contramap(_.toString)
  given Decoder[Hit] = Decoder.decodeString.emapTry(s => Try(Hit.valueOf(s)))
