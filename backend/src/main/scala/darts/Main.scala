package darts

import cats.effect.{ExitCode, IO, IOApp, Ref, Sync}
import darts.game.Game
import fs2.Stream
import fs2.concurrent.Topic
import org.typelevel.log4cats.Logger
import org.typelevel.log4cats.slf4j.Slf4jLogger
import org.typelevel.log4cats.syntax.*

import scala.concurrent.duration.*


object Main extends IOApp {

  override def run(args: List[String]): IO[ExitCode] = for {
    _ <- Logger[IO].info("Starting Darts-Backend")

    game <- Ref.of[IO, Game[_, _]](Game.initial)

    gameTopic <- Topic[IO, Game[_, _]]
    controllerFiber <- Controller.run(gameTopic, game).start
    _ <- Server.run(gameTopic, game).start

    _ <- IO.never.onCancel { for {
      _ <- controllerFiber.cancel
      _ <- Logger[IO].info("Shutting down Darts-Backend")
    } yield () }
  } yield ExitCode.Success

  private implicit def logger[F[_]: Sync]: Logger[F] = Slf4jLogger.getLogger[F]

}
