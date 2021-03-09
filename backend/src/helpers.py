from enum import Enum


class GameMode(Enum):
    STANDARD = "Standard"
    CRICKET = "Cricket"


class GameState(Enum):
    IDLE = 0
    RUNNING = 1
    FINISHED = 2
