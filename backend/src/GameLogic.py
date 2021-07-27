from abc import ABC, abstractmethod
from random import choice
from typing import List, Optional, Tuple, Dict

from Player import Player, PlayerState
from helpers import GameMode, GameState

HIT_ENUM: Dict[str, Tuple[int, int]] = {
    "20o": (20, 1), "20i": (20, 1), "20x2": (20, 2), "20x3": (20, 3),
    "19o": (19, 1), "19i": (19, 1), "19x2": (19, 2), "19x3": (19, 3),
    "18o": (18, 1), "18i": (18, 1), "18x2": (18, 2), "18x3": (18, 3),
    "17o": (17, 1), "17i": (17, 1), "17x2": (17, 2), "17x3": (17, 3),
    "16o": (16, 1), "16i": (16, 1), "16x2": (16, 2), "16x3": (16, 3),
    "15o": (15, 1), "15i": (15, 1), "15x2": (15, 2), "15x3": (15, 3),
    "14o": (14, 1), "14i": (14, 1), "14x2": (14, 2), "14x3": (14, 3),
    "13o": (13, 1), "13i": (13, 1), "13x2": (13, 2), "13x3": (13, 3),
    "12o": (12, 1), "12i": (12, 1), "12x2": (12, 2), "12x3": (12, 3),
    "11o": (11, 1), "11i": (11, 1), "11x2": (11, 2), "11x3": (11, 3),
    "10o": (10, 1), "10i": (10, 1), "10x2": (10, 2), "10x3": (10, 3),
    "9o": (9, 1), "9i": (9, 1), "9x2": (9, 2), "9x3": (9, 3),
    "8o": (8, 1), "8i": (8, 1), "8x2": (8, 2), "8x3": (8, 3),
    "7o": (7, 1), "7i": (7, 1), "7x2": (7, 2), "7x3": (7, 3),
    "6o": (6, 1), "6i": (6, 1), "6x2": (6, 2), "6x3": (6, 3),
    "5o": (5, 1), "5i": (5, 1), "5x2": (5, 2), "5x3": (5, 3),
    "4o": (4, 1), "4i": (4, 1), "4x2": (4, 2), "4x3": (4, 3),
    "3o": (3, 1), "3i": (3, 1), "3x2": (3, 2), "3x3": (3, 3),
    "2o": (2, 1), "2i": (2, 1), "2x2": (2, 2), "2x3": (2, 3),
    "1o": (1, 1), "1i": (1, 1), "1x2": (1, 2), "1x3": (1, 3),
    "Bullseye": (25, 1), "Bullseyex2": (25, 2), "Miss": (0, 0)
}


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

    @abstractmethod
    def _process_hit(self, hit: Tuple[int, int]):
        pass

    def process_hit_message(self, message: str):
        if message in HIT_ENUM:
            return self._process_hit(HIT_ENUM[message])

    def add_player(self, name: str):
        player = Player(name)
        self.init_player(player)
        self.players.append(player)

    def reset_players(self):
        self.active_player = None
        for p in self.players:
            self.init_player(p)

    def add_hit_to_active_player(self, hit: Tuple[int, int]):
        hit_readable = str(hit[0]) if hit[1] == 1 else str(hit[0]) + "x" + str(hit[1])
        self.active_player.hits.append(hit_readable)

    # For testing & debugging purposes only
    def random_hit(self):
        self.process_hit_message(choice(list(HIT_ENUM.keys())))


class CyclicGameLogic(GameLogic, ABC):

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

    def _process_hit(self, hit: Tuple[int, int]) -> GameState:
        if len(self.active_player.hits) < 3 and self.active_player.state == PlayerState.PLAYING:
            print("hit: ", hit)
            points: int = hit[0] * hit[1]
            CyclicGameLogic.add_hit_to_active_player(self, hit)
            score = self.active_player.score["points"] - points
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


class CricketLightGameLogic(CyclicGameLogic):
    identifier: GameMode = GameMode.CRICKET

    def _process_hit(self, hit: HIT_ENUM) -> GameState:
        if len(self.active_player.hits) < 3 and self.active_player.state == PlayerState.PLAYING:
            CyclicGameLogic.add_hit_to_active_player(self, hit)
            if str(hit[0]) in self.active_player.score.keys():
                self.active_player.score[str(hit[0])] = self.active_player.score[str(hit[0])] + hit[1]
                if all(s[0] is "points" or s[1] == 3 for s in self.active_player.score):
                    print("Finished with", self.active_player.score)
                    self.active_player.state = PlayerState.FINISHED
                    return GameState.FINISHED
            if len(self.active_player.hits) >= 3:
                self.active_player.state = PlayerState.BLOCKED
        return GameState.RUNNING

    def init_player(self, player: Player):
        player.hits = []
        player.state = PlayerState.IDLE
        player.score = {
            "points": 0,
            "15": 0,
            "16": 0,
            "17": 0,
            "18": 0,
            "19": 0,
            "20": 0,
            "25": 0
        }
