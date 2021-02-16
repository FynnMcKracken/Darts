import json
from itertools import cycle

HIT_ENUM = {
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


class GameState:

    def __init__(self):
        self.players = []
        self.player_iter = cycle(self.players)
        self.active_player = None
        self.lastHit = None
        self.running = False
        self.finished = False

    def start_game(self):
        self.active_player = next(self.player_iter)
        if self.finished:
            self.reset_game()
        self.running = True

    def process_hit_event(self, message):
        self.lastHit = message
        if len(self.active_player.hits) < 3:
            if self.active_player.update_score(HIT_ENUM[message]):
                self.finished = True
                self.running = False

    def process_miss(self):
        self.process_hit_event("Miss")

    def register_new_player(self, player):
        self.players.append(player)

    def add_new_player(self, name):
        player = Player(name, 501)
        self.players.append(player)

    def next_player(self):
        next_player = next(self.player_iter)
        if self.players[0] == next_player:
            for p in self.players:
                p.reset()
        self.active_player = next_player

    def reset_game(self):
        self.lastHit = None
        self.active_player = None
        self.running = False
        self.finished = False
        self.player_iter = cycle(self.players)
        for p in self.players:
            p.score = 51
            p.reset()

    def to_json(self):
        players_dict = {
            "running": self.running,
            "lastHit": self.lastHit,
            "players": [{**vars(p), "active": self.active_player == p} for p in self.players]
        }
        return json.dumps(players_dict)


class Player:

    def __init__(self, name, score):
        self.name = name
        self.score = score
        self.hits = []
        self.winner = False

    def reset(self):
        self.__init__(self.name, self.score)

    def update_score(self, points):
        self.hits.append(points)
        score = self.score - points
        if score >= 0:
            self.score = self.score - points
            if score == 0:
                self.winner = True
                return True
        return False

