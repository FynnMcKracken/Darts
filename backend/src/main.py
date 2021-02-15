import asyncio
from asyncio.transports import BaseTransport

import json
import serial_asyncio
import websockets
import random

import GameController

HOST = '*'
PORT = 50001

USERS = set()

GAMESTATE = GameController.GameState()


# Websocket communication
async def notify_users():
    if USERS:  # asyncio.wait doesn't accept an empty list
        message = GAMESTATE.to_json()
        await asyncio.wait([user.send(message) for user in USERS])


async def register(websocket):
    USERS.add(websocket)
    await notify_users()


async def unregister(websocket):
    USERS.remove(websocket)
    await notify_users()


async def counter(websocket, path):
    print("Registering websocket %s" % websocket)
    await register(websocket)
    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                if "nextPlayer" in data:
                    GAMESTATE.next_player()
                    GAMESTATE.process_hit_event(random.choice(list(GameController.HIT_ENUM.keys())))
                    await notify_users()
                if "newPlayer" in data:
                    GAMESTATE.add_new_player(data["newPlayer"])
                    await notify_users()
                if "missHit" in data:
                    GAMESTATE.process_miss()
                    await notify_users()
                if "resetScore" in data:
                    GAMESTATE.reset_score()
                    await notify_users()
            except json.JSONDecodeError:
                pass
    except websockets.exceptions.ConnectionClosedError:
        pass
    finally:
        print("Unregistering websocket %s" % websocket)
        await unregister(websocket)


# Serial communication
class Output(asyncio.Protocol):
    transport: BaseTransport
    buf: bytes

    def connection_made(self, transport):
        self.transport = transport
        self.buf = bytes()
        print('port opened', transport)

    def data_received(self, data):
        self.buf += data
        if b'\n' in self.buf:
            lines = self.buf.split(b'\n')
            self.buf = lines[-1]
            for line in lines[:-1]:
                message = line.decode("ascii")
                print('message received:', message)
                if message in GameController.HIT_ENUM:
                    GAMESTATE.process_hit_event(message)
                    loop.create_task(notify_users())

    def connection_lost(self, exc):
        print('port closed')

    def pause_writing(self):
        print('pause writing')
        print(self.transport.get_write_buffer_size())

    def resume_writing(self):
        print(self.transport.get_write_buffer_size())
        print('resume writing')


loop = asyncio.get_event_loop()

# Server init
start_server = websockets.serve(counter, HOST, PORT)

# Serial init
usb_device_file = open("../usb_device", "r")
usb_device = usb_device_file.read().rstrip("\n")
coro = serial_asyncio.create_serial_connection(loop, Output, usb_device, baudrate=9600)

group2 = asyncio.gather(coro)
group1 = asyncio.gather(start_server)

print("Server started.")
loop.run_forever()
