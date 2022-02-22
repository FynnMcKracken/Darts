ThisBuild / version := "0.1.0"

ThisBuild / scalaVersion := "3.1.1"

ThisBuild / scalacOptions ++= Seq(
  "-unchecked",
  "-deprecation",
  "-feature",
  "-language:postfixOps",
  "-language:reflectiveCalls",
  "-language:implicitConversions",
  "-language:higherKinds",
  "-language:existentials"
)

val http4sVersion = "1.0.0-M30"
val circeVersion = "0.14.1"

lazy val root = (project in file("."))
  .settings(
    name := "Darts-Backend",
    libraryDependencies ++= Seq(
      "org.http4s" %% "http4s-core" % http4sVersion,
      "org.http4s" %% "http4s-blaze-server" % http4sVersion,
      "org.http4s" %% "http4s-dsl" % http4sVersion,
      "io.circe" %% "circe-core" % circeVersion,
      "io.circe" %% "circe-generic" % circeVersion,
      "io.circe" %% "circe-parser" % circeVersion,
      "com.fazecast" % "jSerialComm" % "2.9.1",
      "org.typelevel" %% "log4cats-slf4j" % "2.2.0",
      "ch.qos.logback" % "logback-classic" % "1.2.10"
    )
  )
