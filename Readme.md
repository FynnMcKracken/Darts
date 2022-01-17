# Darts

## Hardware

Raspberry Pi Zero W and Arduino Micro

## Getting started

Clone the repository to your computer. Deployment to the Raspberry Pi is handled via deploy scripts.

### Configuration

In the project directory create a folder _config_ with the following files:

- _delpoy-host_ containing the ip address or hostname of your ssh-enabled Raspberry Pi
- _controller-device_ containing the physical device of the arduino on your Raspberry Pi (e.g. _/dev/ttyACM0_). This can be determined by running `arduino-cli board list`.
- _dartboard_ containing the idetifier for your dartboard. Supported boards are _Aspiria_ANS_16_013_ and _Noname_Licorice_

### Controller

On the Raspberry Pi run

```
sudo apt-get update
sudo apt-get upgrade -y

curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
echo 'export PATH=$PATH:/home/pi/bin' >> .bashrc

arduino-cli config init

arduino-cli core update-index
arduino-cli core install arduino:avr

arduino-cli lib install TimerOne
```

The controller can be deployed by running `./go deploy` in the directory _controller_ on your computer


### Backend

On the Raspberry Pi run

```
sudo apt install python3-pip
pip3 install pyserial-asyncio websockets
```

To have the backend run as a service create _/lib/systemd/system/darts.service_ on the Raspberry Pi with

```
[Unit]
Description=Darts
After=multi-user.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/backend/src
ExecStart=python3 -u main.py
Restart=on-abort

[Install]
WantedBy=multi-user.target
```

To start the service now and enable starting the service on boot run 

```
sudo systemctl enable darts
sudo systemctl start darts
```

The backend can be deployed by running `./go deploy` in the directory _backend_ on your computer

Logs can be inspected with `journalctl -f -u darts` on the Raspberry Pi


### Frontend

On the Raspberry Pi (in _/home/pi_) run

```
sudo apt install nginx
mkdir frontend
```

In _/etc/nginx/sites-enabled/default_: change "/var/www/html" to "/home/pi/frontend"

```
sudo systemctl start nginx
```

The frontend can be deployed by running `./go deploy` in the directory _frontend_ on your computer
