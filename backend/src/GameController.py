import json
from enum import Enum
from random import choice

from typing import List, Dict, Optional
from abc import ABC, abstractmethod

HIT_ENUM: Dict[str, int] = {
    "20o": 20, "20i": 20, "20x2": 40, "20x3": 60,
    "19o": 19, "19i": 19, "19x2": 38, "19x3": 57,
    "18o": 18, "18i": 18, "18x2": 36, "18x3": 54,
    "17o": 17, "17i": 17, "17x2": 34, "17x3": 51,
    "16o": 16, "16i": 16, "16x2": 32, "16x3": 48,
    "15o": 15, "15i": 15, "15x2": 30, "15x3": 45,
    "14o": 14, "14i": 14, "14x2": 28, "14x3": 42,
    "13o": 13, "13i": 13, "13x2": 26, "13x3": 39,
    "12o": 12, "12i": 12, "12x2": 24, "12x3": 36,
    "11o": 11, "11i": 11, "11x2": 22, "11x3": 33,
    "10o": 10, "10i": 10, "10x2": 20, "10x3": 30,
    "9o": 9, "9i": 9, "9x2": 18, "9x3": 27,
    "8o": 8, "8i": 8, "8x2": 16, "8x3": 24,
    "7o": 7, "7i": 7, "7x2": 14, "7x3": 21,
    "6o": 6, "6i": 6, "6x2": 12, "6x3": 18,
    "5o": 5, "5i": 5, "5x2": 10, "5x3": 15,
    "4o": 4, "4i": 4, "4x2": 8, "4x3": 12,
    "3o": 3, "3i": 3, "3x2": 6, "3x3": 9,
    "2o": 2, "2i": 2, "2x2": 4, "2x3": 6,
    "1o": 1, "1i": 1, "1x2": 2, "1x3": 3,
    "Bullseye": 25, "Bullseyex2": 50, "Miss": 0
}


class GameState(Enum):
    IDLE = 0
    RUNNING = 1
    FINISHED = 2


class GameMode(Enum):
    STANDARD = "standard"


class PlayerState(str, Enum):
    IDLE = "Idle"
    PLAYING = "Playing"
    BLOCKED = "Blocked"
    FINISHED = "Finished"


class Player:
    hits: List[int]

    def __init__(self, name: str):
        self.name: str = name
        self.score: Dict[str, int] = {}
        self.hits: List[int] = []
        self.state: PlayerState = PlayerState.IDLE


class GameController:

    def __init__(self):
        self.lastHit = "Miss"
        self.running_state = GameState.IDLE
        self.gameLogic = StandardGameLogic()

    def start_game(self):
        if self.running_state == GameState.FINISHED:
            self.reset_game()
        self.gameLogic.next_player()
        self.running_state = GameState.RUNNING

    def process_hit_message(self, message: str):
        self.lastHit = message
        if self.running_state == GameState.RUNNING:
            self.running_state = self.gameLogic.process_hit(message)

    def process_miss(self):
        self.process_hit_message("Miss")

    def add_new_player(self, name: str):
        if self.running_state != GameState.RUNNING:
            self.gameLogic.add_player(name)

    def next_player(self):
        if self.running_state == GameState.RUNNING:
            self.gameLogic.next_player()

    def reset_game(self):
        self.lastHit = None
        self.running_state = GameState.IDLE
        self.gameLogic.reset_players()

    def to_json(self):
        players_dict = {
            "running": self.running_state == GameState.RUNNING,
            "lastHit": self.lastHit,
            "gameMode": self.gameLogic.identifier.value,
            "players": [{**vars(p)} for p in self.gameLogic.players]
        }
        print(json.dumps(players_dict))
        return json.dumps(players_dict)

    # For testing & debugging purposes only
    def random_hit(self):
        self.process_hit_message(choice(list(HIT_ENUM.keys())))


class GameLogic(ABC):
    active_player: Optional[Player]
    players: List[Player]
    identifier: GameMode

    def __init__(self):
        self.players = []
        self.reset_players()

    @property
    @abstractmethod
    def identifier(self):
        pass

    @abstractmethod
    def init_player(self, player: Player):
        pass

    def add_player(self, name: str):
        player = Player(name)
        self.init_player(player)
        self.players.append(player)

    def reset_players(self):
        self.active_player = None
        for p in self.players:
            self.init_player(p)


class CyclicGameLogic(GameLogic, ABC):

    def __init__(self):
        super().__init__()

    def reset_players(self):
        GameLogic.reset_players(self)

    def next_player(self):
        if self.active_player is None and len(self.players) > 0:
            self.active_player = self.players[0]
            self.active_player.state = PlayerState.PLAYING
        else:
            if self.active_player.state is not PlayerState.FINISHED:
                self.active_player.state = PlayerState.IDLE

            for i in range(len(self.players)):
                if self.players[i] == self.active_player:
                    next_player_1 = self.players[(i + 1) % len(self.players)]
                    if next_player_1.state == PlayerState.IDLE:
                        next_player_1.state = PlayerState.PLAYING
                        self.active_player = next_player_1
                        break

            if self.players[0] == self.active_player:
                for p in self.players:
                    p.hits = []


class StandardGameLogic(CyclicGameLogic):
    identifier: GameMode = GameMode.STANDARD

    def process_hit(self, message: str) -> GameState:
        if len(self.active_player.hits) < 3 and self.active_player.state == PlayerState.PLAYING:
            hit: int = HIT_ENUM[message]
            self.active_player.hits.append(hit)
            score = self.active_player.score["points"] - hit
            if score >= 0:
                self.active_player.score["points"] = score
                if score == 0:
                    self.active_player.state = PlayerState.FINISHED
                    return GameState.FINISHED
                elif len(self.active_player.hits) == 3:
                    self.active_player.state = PlayerState.BLOCKED
            else:
                self.active_player.state = PlayerState.BLOCKED
        return GameState.RUNNING

    def init_player(self, player: Player):
        player.hits = []
        player.state = PlayerState.IDLE
        player.score = {"points": 501}
