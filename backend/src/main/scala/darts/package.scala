package darts

import cats.Monad
import cats.effect.{IO, Ref, Sync}
import cats.implicits.*
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


extension [F[_]: Monad, A](self: Ref[F, A])
  def optionUpdateAndGet(f: A => Option[A]): F[Option[A]] = for {
    value <- self.get
    valueUpdated = f(value)
    _ <- valueUpdated.traverse_(self.set(_))
  } yield valueUpdated

  def optionUpdateAndGetF(f: A => F[Option[A]]): F[Option[A]] = for {
    value <- self.get
    valueUpdated <- f(value)
    _ <- valueUpdated.traverse_(self.set(_))
  } yield valueUpdated
