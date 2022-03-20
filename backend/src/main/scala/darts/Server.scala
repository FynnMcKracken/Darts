package darts

import cats.effect.{ExitCode, IO, Ref, Sync}
import darts.game.{Game, GameMode, Hit}
import fs2.concurrent.Topic
import fs2.{Pipe, Stream}
import io.circe.generic.auto.*
import io.circe.parser.decode
import io.circe.syntax.*
import org.http4s.blaze.server.BlazeServerBuilder
import org.http4s.dsl.io.*
import org.http4s.server.websocket.WebSocketBuilder
import org.http4s.websocket.WebSocketFrame
import org.http4s.websocket.WebSocketFrame.Text
import org.http4s.{HttpRoutes, Response}
import org.typelevel.log4cats.Logger
import org.typelevel.log4cats.slf4j.Slf4jLogger
import cats.implicits.*

import java.util.UUID


object Server {
  def run(appStateTopic: Topic[IO, AppState[_]], appState: Ref[IO, AppState[_]]): IO[Unit] = stream(appStateTopic, appState).compile.drain

  private def stream(appStateTopic: Topic[IO, AppState[_]], appState: Ref[IO, AppState[_]]): Stream[IO, ExitCode] = BlazeServerBuilder[IO]
    .bindHttp(port = 50001, host = "0.0.0.0")
    .withHttpWebSocketApp(routes(_, appStateTopic, appState).orNotFound)
    .serve

  private def routes(webSocketBuilder: WebSocketBuilder[IO], appStateTopic: Topic[IO, AppState[_]], appState: Ref[IO, AppState[_]]): HttpRoutes[IO] = HttpRoutes.of[IO] {
    case GET -> Root => gameWebsocketRoute(webSocketBuilder, appStateTopic, appState)
  }

  private def gameWebsocketRoute(webSocketBuilder: WebSocketBuilder[IO], appStateTopic: Topic[IO, AppState[_]], appState: Ref[IO, AppState[_]]): IO[Response[IO]] = {
    val send: Stream[IO, WebSocketFrame] = (Stream.eval(appState.get) ++ appStateTopic.subscribe(100))
      .map(state1 => Text(state1.asJson.toString))
      .evalMap(message => Logger[IO].debug(s"send message: ${message.str}") *> IO.pure(message))

    val receive: Pipe[IO, WebSocketFrame, Unit] = stream => appStateTopic.publish(stream.through(process(appState)))

    webSocketBuilder.build(send, receive)
  }

  private def process(appState: Ref[IO, AppState[_]]): Pipe[IO, WebSocketFrame, AppState[_]] = _.collect {
    case Text(message, _) => message
  }.evalMapFilter { message =>
    appState.optionUpdateAndGetF(_.processClientMessage(message))
  }

  private given[F[_]: Sync]: Logger[F] = Slf4jLogger.getLogger[F]
}
