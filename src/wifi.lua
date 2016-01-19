ip = wifi.sta.getip()
print(ip)
if ip == nil then
  wifi.setmode(wifi.STATION)
  wifi.sta.config(SSID,PASSWORD)
  wifi.sta.connect()
end
