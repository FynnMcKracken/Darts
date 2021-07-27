import json

from GameLogic import CricketLightGameLogic, StandardGameLogic, GameLogic
from helpers import GameState, GameMode


class GameController:

    def __init__(self):
        self.lastHit = "Miss"
        self.running_state = GameState.IDLE
        self.gameLogic = StandardGameLogic()

    def process_change_mode(self, message: str):
        if message == GameMode.STANDARD.value:
            self.__change_logic(StandardGameLogic())
        elif message == GameMode.CRICKET.value:
            self.__change_logic(CricketLightGameLogic())
        self.running_state = GameState.IDLE

    def __change_logic(self, logic: GameLogic):
        for player in self.gameLogic.players:
            logic.add_player(player.name)
        self.gameLogic = logic

    def start_game(self):
        if self.running_state == GameState.FINISHED:
            self.reset_game()
        self.gameLogic.next_player()
        self.running_state = GameState.RUNNING

    def process_hit_message(self, message: str):
        self.lastHit = message
        if self.running_state == GameState.RUNNING:
            self.running_state = self.gameLogic.process_hit_message(message)

    def process_miss(self):
        self.process_hit_message("Miss")

    def add_new_player(self, name: str):
        if self.running_state != GameState.RUNNING:
            self.gameLogic.add_player(name)

    def remove_player(self, player_uuid: str):
        player = next(player for player in self.gameLogic.players if player.uuid == player_uuid)
        self.gameLogic.players.remove(player)

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
            # Lazy & inflexible way to encode players, TODO: Custom encoding for player and their fields
            "players": [{**vars(p)} for p in self.gameLogic.players]
        }
        print(json.dumps(players_dict))
        return json.dumps(players_dict)

    def random_hit(self):
        self.gameLogic.random_hit()
