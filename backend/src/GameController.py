class GameController:

    def __init__(self):
        self.players = []
        self.current_player = -1

    def register_new_player(self, player):
        self.players.append(player)

    def next_player(self):
        self.current_player = (self.current_player + 1) % len(self.players)



