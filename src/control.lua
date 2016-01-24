jsonrpc = require 'jsonrpc'
local hcsr04 = require 'hcsr04'
local val = 0

function measure()
  local dist = hcsr04.measure_avg()
  if dist > MINDIST and dist < MAXRANGE + MAXDIST then
    print(dist)
    tmr.stop(MEASURE_TIMER)
    if dist > MAXDIST then
      val = 100
    else
      val = ((dist - MINDIST) / RANGE) * 100
    end
    jsonrpc.setBrightness(LIGHT, val, 1000)
    return true
  end
  if dist < MINDIST and dist ~= -1 then
    tmr.stop(MEASURE_TIMER)
    jsonrpc.setBrightness(LIGHT, 0, 1000)
    jsonrpc.lightOff(LIGHT)
    return true
  end
end

function startTimer()
  tmr.stop(MEASURE_TIMER)
  tmr.alarm(MEASURE_TIMER, REFRESH, 1, measure)
end

wifi.sta.eventMonReg(wifi.STA_GOTIP, function()
  wifi.sta.eventMonReg(wifi.STA_GOTIP, "unreg")
  print(wifi.sta.getip())
  hcsr04.init(TRIG, ECHO, AVG)
  jsonrpc.init(
    PORT,
    SERVER,
    function()
      startTimer()
    end)
end)

wifi.sta.eventMonReg(wifi.STA_IDLE, function() wifi.sta.connect() end)

wifi.sta.eventMonStart()