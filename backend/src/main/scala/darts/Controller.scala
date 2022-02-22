package darts

import cats.effect.{IO, Ref, Sync}
import com.fazecast.jSerialComm.SerialPort
import darts.game.{Game, Hit}
import fs2.concurrent.Topic
import fs2.{Pipe, Stream}
import org.typelevel.log4cats.Logger
import org.typelevel.log4cats.slf4j.Slf4jLogger

import scala.io.Source
import scala.util.Try


object Controller {

  def run(gameTopic: Topic[IO, Game[_, _]], game: Ref[IO, Game[_, _]]): IO[Unit] = for {
    controllerDevice <- readFile("controller-device").map(_.stripLineEnd)

    _ <- openSerialPort(controllerDevice).bracket { serialPort =>
      gameTopic.publish(stream(serialPort).through(process(game))).compile.drain
    }{ serialPort =>
      closeSerialPort(serialPort)
    }
  } yield ()

  private def stream(serialPort: SerialPort): Stream[IO, Hit] = Stream
    .evalSeq(readBytes(serialPort))
    .repeat
    .through(fs2.text.utf8.decode)
    .through(fs2.text.lines)
    .mapFilter(hit => Try(Hit.valueOf(hit)).toOption)

  private def process(game: Ref[IO, Game[_, _]]): Pipe[IO, Hit, Game[_, _]] = _.evalMap { hit => for {
    _ <- Logger[IO].debug(s"hit $hit")
    game1 <- game.updateAndGet(_.processHit(hit))
  } yield game1 }

  private def openSerialPort(controllerDevice: String): IO[SerialPort] = for {
    serialPort <- IO.delay(SerialPort.getCommPort(controllerDevice))
    _ <- IO.delay(serialPort.openPort())
    _ <- IO.delay(serialPort.setComPortTimeouts(SerialPort.TIMEOUT_READ_SEMI_BLOCKING, 0, 0))
    _ <- IO.delay(serialPort.flushIOBuffers())
  } yield serialPort

  private def readBytes(serialPort: SerialPort): IO[Seq[Byte]] = IO.delay {
    val readBuffer = new Array[Byte](16)
    val numRead = serialPort.readBytes(readBuffer, readBuffer.length)
    readBuffer.toSeq.take(numRead)
  }

  private def closeSerialPort(serialPort: SerialPort): IO[Unit] = Logger[IO].info("close controller port") *> IO.delay(serialPort.closePort())

  private implicit def logger[F[_]: Sync]: Logger[F] = Slf4jLogger.getLogger[F]

}
