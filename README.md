# NodeMCU LIFX control
> Control LIFX light brightness with NodeMCU,
> hc-sr04 range sensor and lightsd server.

This is clone of [https://github.com/ra100/nodemcu-lightsd](https://github.com/ra100/nodemcu-lightsd) with lightsd switched for lifx rest server.

## Requirements
- LIFX bulbs
- NodeMCU module
  - firmware = 1.5.4 - float, with modules: node, file, gpio, wifi, net, http, tmr - [http://nodemcu-build.com/](http://nodemcu-build.com/)

- HC-SR04 ultrasonic sensor
- LIFX REST server - [https://github.com/ra100/lifx-rest-web](https://github.com/ra100/lifx-rest-web)

## Contents
- `config.lua.default` - default configuration, rename to `config.lua` and change settings
- `control.lua` - main code to bridge sensor and server
- `hcsr04.lua` - modified lua module from [https://github.com/sza2/node_hcsr04](https://github.com/sza2/node_hcsr04)
- `init.lua` - init script to compile .lua to .lc and start `wifi.lua` and `control.lc`
- `lifx.lua` - module for communication with `lifx-rest` server via http calls
- `wifi.lua` - connects to WiFi network configured in `config.lua`

## Usage
- Connect HC-SR04 to NodeMCU. Default pins are: TRIG - 5, ECHO - 6, Gnd - GND, VCC - VU (you need 5V).
- Edit configuration in `config.lua.default` and rename it to `config.lua`. Configuration options:
  - `SSID` [required] - network SSID
  - `PASSWORD` [required] - network password
  - `LIGHT` [required] - name of light you want to control
  - `MINDIST` [required] - distance below which light should turn off [in meters]
  - `MAXDIST` [required] - distance where light brightness should turn to 100% [in meters]
  - `MAXRANGE` [required] - range above MAXDIST where sensor should detect movement (and set brightness to 100%) [in meters]
  - `BASEURL` [required] - full url where to find API `http://10.0.0.5:3000/api/v1`
  - `IP` [optional] - IP address if you don't want to let DHCP assign address, makes reconnect much faster
  - `GATEWAYIP` [optinoal] - if you set IP, set also gateway
  - `TRIG` [required] - pin number where you connect `trig` wire from hcsr04
  - `ECHO` [required] - pin number where you connect `echo` wire from hcsr04
  - `REFRESH` [required] - how often should script check for distance

- Upload files to NodeMCU.
- Restart.
- Wave your hand in front of range sensor.

## How it works
Init script connect to wifi and checks if connection is established. Then creates TCP connection to lightsd server. After that distance measurement starts. When is measured distance in range (from 0 to MAXDIST + MAXRANGE) value is calculated 0 - 100 which represents brightness level. That is sent to lightsd server via jsonrpc. Before first value change, current light state is requested and saved (to preserve hue, saturation, warmth). If light is Off, next command is to turn the light On and after that brightness value changes. New brightness value can not be sent before confirmation packet from lightsd is received. While NodeMCU is communicating with lightsd server, distance measurement is on hold, this prevents sending too much requests to server and responses which could exhaust memory.

## TODO

- [x] optimize memory usage
- [ ] light tags/groups support

## License
GNU GPLv3
