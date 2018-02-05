ip = wifi.sta.getip()
print('Found IP:' .. ip)
if ip == nil and IP == '' then
  wifi.setmode(wifi.STATION)
  wifi.setphymode(wifi.PHYMODE_N)
  wifi.sta.config(SSID, PASSWORD, 1)
  wifi.sleeptype(wifi.LIGHT_SLEEP)
  wifi.sta.autoconnect(1)
  wifi.sta.connect()
else
  wifi.setmode(wifi.STATION)
  wifi.sta.config(SSID, PASSWORD, 1)
  wifi.sleeptype(wifi.LIGHT_SLEEP)
  wifi.sta.connect()
  wifi.sta.setip({ip=IP,netmask="255.255.255.0",gateway=GETEWAYIP})
end
