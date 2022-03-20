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
  def run(appStateTopic: Topic[IO, AppState[_]], appState: Ref[IO, AppState[_]]): IO[Unit] = for {
    controllerDevice <- readFile("controller-device").map(_.stripLineEnd)

    _ <- openSerialPort(controllerDevice).bracket { serialPort =>
      appStateTopic.publish(stream(serialPort).through(process(appState))).compile.drain
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

  private def process(appState: Ref[IO, AppState[_]]): Pipe[IO, Hit, AppState[_]] = _.evalMapFilter { hit =>
    for {
      _ <- Logger[IO].debug(s"hit $hit")
      appState1 <- appState.optionUpdateAndGet(_.processHit(hit))
    } yield appState1
  }

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

  private given[F[_]: Sync]: Logger[F] = Slf4jLogger.getLogger[F]
}
