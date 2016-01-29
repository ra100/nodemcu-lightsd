ip = wifi.sta.getip()
print(ip)
if ip == nil then
  wifi.setmode(wifi.STATION)
  wifi.setphymode(wifi.PHYMODE_N)
  wifi.sta.config(SSID, PASSWORD, 1)
  wifi.sleeptype(wifi.LIGHT_SLEEP)
  wifi.sta.autoconnect(1)
  wifi.sta.connect()
end
