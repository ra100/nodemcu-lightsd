lifx = require 'lifx'
local hcsr04 = require 'hcsr04'
local val = 0
local prev = -1 -- previous distance value

function measure()
  local dist = hcsr04.measure()
  if (math.abs(dist - prev) < 0.1) then
    if DEBUG then print(dist) end
    local d = (dist + prev) / 2
    if d > MINDIST and d < (MAXRANGE + MAXDIST) then
      if d > MAXDIST then
        val = 100
      else
        val = ((d - MINDIST) / RANGE) * 100
      end
      lifx.setBrightness(val, FADETIME, LIGHT)
      return true
    elseif d < MINDIST and d > 0 then
      lifx.lightOff(LIGHT)
      return true
    end
  end
  prev = dist
end

function startTimer()
  if DEBUG then print('Timer started') end
  tmr.alarm(MEASURE_TIMER, REFRESH, 1, measure)
end

wifi.sta.eventMonReg(wifi.STA_GOTIP, function()
  wifi.sta.eventMonReg(wifi.STA_GOTIP, 'unreg')
  if DEBUG then print(wifi.sta.getip()) end
  hcsr04.init(TRIG, ECHO, AVG)
  lifx.init(BASEURL, LIGHT, startTimer)
end)

wifi.sta.eventMonReg(wifi.STA_IDLE, function() wifi.sta.connect() end)

wifi.sta.eventMonStart()
