local lifx = {}

local light = nil
local baseurl = nil
local sending = false
local defaultDuration = 200

local function requestCallback(code, data)
  sending = false
  if (code < 0) then
    print("HTTP request failed")
  else
    print(code, data)
  end
end

local function sendBrightness(brightness, dur, l)
  if sending then 
    if DEBUG then print('sending in progress') end
    return nil
  end
  local duration = dur or defaultDuration
  local tmplight = l or light
  http.request(
    baseurl .. '/lights/' .. tmplight,
    'PATCH',
    'Content-Type: application/json\r\n',
    '{"brightness": '.. brightness ..', "duration": '.. dur ..'}',
    requestCallback)
end

local function sendPower(power, dur, l)
  if sending then 
    if DEBUG then print('sending in progress') end
    return nil
  end
  sending = true
  local duration = dur or defaultDuration
  local tmplight = l or light
  http.request(
    baseurl .. '/lights/' .. tmplight,
    'PATCH',
    'Content-Type: application/json\r\n',
    '{"power": '.. power ..', "duration": '.. dur ..'}',
    requestCallback)
end

function lifx.init(url, l, callback)
  baseurl = url
  light = l
  callback()
end

-- turn the light on
function lifx.lightOn(l)
  sendPower(1, defaultDuration, l)
end

-- turn the light off
function lifx.lightOff(l)
  sendPower(0, 0, l)
end

-- lightsd code, value 0 - 100
function lifx.setBrightness(value, duration, light)
  sendBrightness(value, duration, light)
end

return lifx
