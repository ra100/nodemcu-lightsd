local jsonrpc = require 'jsonrpc'
local hcsr04 = require 'hcsr04'
local val = 0
local prev = -1 -- previous distance value
local p = 0

function unpause()
  p = p - 1
end

function pause()
  p = p + 1
end

function measure()
  if (p ~= 0) then
    return false
  end
  pause()
  local dist = hcsr04.measure()
  unpause()
  if (math.abs(dist - prev) < 0.1) then
    if DEBUG then print(dist) end
    local d = (dist + prev) / 2
    if d > MINDIST and d < (MAXRANGE + MAXDIST) then
      pause()
      print("heap1: " .. node.heap())
      if d > MAXDIST then
        val = 100
      else
        val = ((d - MINDIST) / RANGE) * 100
      end
      jsonrpc.setBrightness(LIGHT, val, FADETIME, unpause)
      return true
    elseif d < MINDIST and d > 0 then
      print("heap2: " .. node.heap())
      pause()
      pause()
      jsonrpc.setBrightness(LIGHT, 0, FADETIME, unpause)
      jsonrpc.lightOff(LIGHT, unpause)
      print("heap3: " .. node.heap())
      return true
    end
  end
  prev = dist
end

function startTimer()
  if DEBUG then print("Timer started") end
  tmr.alarm(MEASURE_TIMER, REFRESH, 1, measure)
end

wifi.sta.eventMonReg(wifi.STA_GOTIP, function()
  wifi.sta.eventMonReg(wifi.STA_GOTIP, "unreg")
  if DEBUG then print(wifi.sta.getip()) end
  hcsr04.init(TRIG, ECHO, AVG)
  jsonrpc.init(PORT, SERVER, startTimer)
end)

wifi.sta.eventMonReg(wifi.STA_IDLE, function() wifi.sta.connect() end)

wifi.sta.eventMonStart()