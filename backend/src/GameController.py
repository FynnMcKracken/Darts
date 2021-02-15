import json


class GameState:

    def __init__(self):
        self.players = [
            Player("Foo bo", 501),
            Player("Bar bo", 501),
            Player("Baz bo", 501)
        ]
        self.active_player = self.players[0]
        self.lastHit = None

    def register_new_player(self, player):
        self.players.append(player)

    def add_new_player(self, name):
        player = Player(name, 0)
        self.players.append(player)

    def next_player(self):
        for i in range(len(self.players)):
            if self.players[i] == self.active_player:
                print("Changing active player: Player", i)
                self.active_player = self.players[(i + 1) % len(self.players)]
                break

    def to_json(self):
        players_dict = {
            "lastHit": self.lastHit,
            "players": [{**vars(x), "active": self.active_player == x} for x in self.players]
        }
        return json.dumps(players_dict)


class Player:

    def __init__(self, name, score):
        self.name = name
        self.score = score

    def update_score(self, score):
        self.score = score

