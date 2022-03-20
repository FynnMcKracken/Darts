package darts

import cats.effect.{ExitCode, IO, IOApp, Ref, Sync}
import darts.game.{Game, Hit, Standard}
import fs2.Stream
import fs2.concurrent.Topic
import io.circe.generic.auto.*
import io.circe.{Encoder, Json}
import org.typelevel.log4cats.Logger
import org.typelevel.log4cats.slf4j.Slf4jLogger
import org.typelevel.log4cats.syntax.*

import java.util.UUID
import scala.concurrent.duration.*


object Main extends IOApp {
  override def run(args: List[String]): IO[ExitCode] = for {
    _ <- Logger[IO].info("Starting Darts-Backend")

    appState <- Ref.of[IO, AppState[_]](AppState.initial)

    appStateTopic <- Topic[IO, AppState[_]]

    controllerFiber <- Controller.run(appStateTopic, appState).start
    _ <- Server.run(appStateTopic, appState).start

    _ <- IO.never.onCancel { for {
      _ <- controllerFiber.cancel
      _ <- Logger[IO].info("Shutting down Darts-Backend")
    } yield () }
  } yield ExitCode.Success

  private given[F[_]: Sync]: Logger[F] = Slf4jLogger.getLogger[F]
}
