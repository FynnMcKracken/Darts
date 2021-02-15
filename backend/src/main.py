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

# This is only used to validate serial communication
HIT_ENUM = [
    "20o", "20i", "20", "20x2", "20x3",
    "19o", "19i", "19x2", "19x3",
    "18o", "18i", "18x2", "18x3",
    "17o", "17i", "17x2", "17x3",
    "16o", "16i", "16x2", "16x3",
    "15o", "15i", "15x2", "15x3",
    "14o", "14i", "14x2", "14x3",
    "13o", "13i", "13x2", "13x3",
    "12o", "12i", "12x2", "12x3",
    "11o", "11i", "11x2", "11x3",
    "10o", "10i", "10x2", "10x3",
    "9o", "9i", "9x2", "9x3",
    "8o", "8i", "8x2", "8x3",
    "7o", "7i", "7x2", "7x3",
    "6o", "6i", "6x2", "6x3",
    "5o", "5i", "5x2", "5x3",
    "4o", "4i", "4x2", "4x3",
    "3o", "3i", "3x2", "3x3",
    "2o", "2i", "2x2", "2x3",
    "1o", "1i", "1x2", "1x3",
    "Bullseye", "Bullseyex2"
]


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
                    GAMESTATE.lastHit = random.choice(HIT_ENUM)
                    await notify_users()
                if "newPlayer" in data:
                    GAMESTATE.add_new_player(data["newPlayer"])
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
                if message in HIT_ENUM:
                    GAMESTATE.lastHit = message
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
