package darts

import cats.effect.{IO, Sync}
import fs2.Stream

import scala.io.Source


def readFile(fileName: String): IO[String] = IO.delay(Source.fromFile(fileName)).bracket { source =>
  IO.delay(source.mkString)
} { source =>
  IO.delay(source.close())
}


extension [A](self: List[A])
  def spanNot(predicate: A => Boolean): (List[A], List[A]) = self.span(!predicate(_))


extension [F[_], O](self: Stream[F, O])
  def mapFilter[O2](f: O => Option[O2]): Stream[F, O2] = self.collect(f.unlift)
