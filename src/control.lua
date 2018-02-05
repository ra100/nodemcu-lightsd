jsonrpc = require 'jsonrpc'
local hcsr04 = require 'hcsr04'
local val = 0
local prev = -1 -- previous distance value

function measure()
  if (not jsonrpc.getPause()) then
    return false
  end
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
      jsonrpc.setBrightness(LIGHT, val, FADETIME)
      return true
    elseif d < MINDIST and d > 0 then
      jsonrpc.lightOff(LIGHT)
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
  jsonrpc.init(PORT, SERVER, LIGHT, startTimer)
end)

wifi.sta.eventMonReg(wifi.STA_IDLE, function() wifi.sta.connect() end)

wifi.sta.eventMonStart()
