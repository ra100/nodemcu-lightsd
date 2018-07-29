local lifx = require 'lifx'
local hcsr04 = require 'hcsr04'
local val = 0
local prev = -1 -- previous distance value

function measure_callback(dist)
  if DEBUG then print('measure ' .. dist) end
  if (math.abs(dist - prev) < 0.2) then
    if DEBUG then print('distance ' .. dist) end
    local d = (prev + dist) / 2
    if d > MINDIST and d < (MAXRANGE + MAXDIST) then
      if d > MAXDIST then
        val = 100
      else
        val = ((d - MINDIST) / RANGE) * 100
      end
      if DEBUG then print('Brightness ' .. val) end
      lifx.setBrightness(val, FADETIME, LIGHT)
    elseif d < MINDIST and d > 0 then
      if DEBUG then print('Light Off') end
      lifx.lightOff(LIGHT)
    end
  end
  prev = dist
  if node.heap() < 4000 then node.restart() end
  tmr.delay(10)
end

function startTimer()
  if DEBUG then print('Timer started') end
  tmr.alarm(3, REFRESH, tmr.ALARM_AUTO, function() hcsr04(TRIG, ECHO, AVG, MEASURE_TIMER, measure_callback); end)
end

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function()
  wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, 'unreg')
  if DEBUG then print(wifi.sta.getip()) end
  lifx.init(BASEURL, LIGHT, startTimer)
end)

wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi.sta.connect)
