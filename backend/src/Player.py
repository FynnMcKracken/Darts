import uuid
from enum import Enum
from typing import List, Dict


class PlayerState(str, Enum):
    IDLE = "Idle"
    PLAYING = "Playing"
    BLOCKED = "Blocked"
    FINISHED = "Finished"


class Player:
    hits: List[str]

    def __init__(self, name: str):
        self.uuid: str = uuid.uuid4().hex
        self.name: str = name
        self.score: Dict[str, int] = {}
        self.hits: List[str] = []
        self.state: PlayerState = PlayerState.IDLE
