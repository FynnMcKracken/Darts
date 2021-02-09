import json


class GameState:

    def __init__(self):
        self.players = [
            Player("Foo bo", 123, True),
            Player("Bar bo", 8008, False),
            Player("Baz bo", 47, False)
        ]
        self.current_player = 0
        self.lastHit = None

    def register_new_player(self, player):
        self.players.append(player)

    def add_new_player(self, name):
        player = Player(name, 0, False)
        self.players.append(player)

    def next_player(self):
        self.current_player = (self.current_player + 1) % len(self.players)
        for i in range(len(self.players)):
            if self.players[i].active:
                print("Changing active player: Player", i)
                self.players[i].active = False
                self.players[(i + 1) % len(self.players)].active = True
                break

    def to_json(self):
        players_dict = {
            "lastHit": self.lastHit,
            "players": [vars(x) for x in self.players]
        }
        return json.dumps(players_dict)


class Player:

    def __init__(self, name, score, active):
        self.name = name
        self.score = score
        self.active = active

    def update_score(self, score):
        self.score = self.score + score

