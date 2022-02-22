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


object Server {

  def run(gameTopic: Topic[IO, Game[_, _]], game: Ref[IO, Game[_, _]]): IO[Unit] = stream(gameTopic, game).compile.drain

  private def stream(gameTopic: Topic[IO, Game[_, _]], game: Ref[IO, Game[_, _]]): Stream[IO, ExitCode] = BlazeServerBuilder[IO]
    .bindHttp(port = 50001, host = "0.0.0.0")
    .withHttpWebSocketApp(routes(_, gameTopic, game).orNotFound)
    .serve

  private def routes(webSocketBuilder: WebSocketBuilder[IO], gameTopic: Topic[IO, Game[_, _]], game: Ref[IO, Game[_, _]]): HttpRoutes[IO] = HttpRoutes.of[IO] {
    case GET -> Root => gameWebsocketRoute(webSocketBuilder, gameTopic, game)
  }

  private def gameWebsocketRoute(webSocketBuilder: WebSocketBuilder[IO], gameTopic: Topic[IO, Game[_, _]], game: Ref[IO, Game[_, _]]): IO[Response[IO]] = {
    val send: Stream[IO, WebSocketFrame] = (Stream.eval(game.get) ++ gameTopic.subscribe(100))
      .map(game1 => Text(game1.asJson.toString))
      .evalMap(message => Logger[IO].debug(s"send message: ${message.str}") *> IO.pure(message))

    val receive: Pipe[IO, WebSocketFrame, Unit] = stream => gameTopic.publish(stream.through(process(game)))

    webSocketBuilder.build(send, receive)
  }

  private def process(game: Ref[IO, Game[_, _]]): Pipe[IO, WebSocketFrame, Game[_, _]] = _.collect {
    case Text(message, _) => message
  }.evalMapFilter { message =>
    decode[ClientMessage](message) match {
      case Right(message1) => Logger[IO].debug(s"message received: $message") *> game.updateAndGet(processClientMessage(_, message1)).map(Some(_))
      case Left(_) => Logger[IO].warn(s"invalid message received: $message").as(None)
    }
  }

  private def processClientMessage(game: Game[_, _], clientMessage: ClientMessage): Game[_, _] = clientMessage match {
    case ClientMessage.StartGame => Game(game.gameMode, game.players).start
    case ClientMessage.ResetGame => Game(game.gameMode, game.players)
    case ClientMessage.NextPlayer => game.advancePlayer
    case ClientMessage.MissHit => game.processHit(Hit.Miss)
    case ClientMessage.AddPlayer(name: String) => game.addPlayer(name)
    case ClientMessage.RemovePlayer(uuid: String) => game.removePlayer(uuid)
    case ClientMessage.ChangeGameMode(gameMode: GameMode) => Game(gameMode, game.players)
  }

  private implicit def logger[F[_]: Sync]: Logger[F] = Slf4jLogger.getLogger[F]

}
