local jsonrpc = {}

List = require 'list'

local ip = nil
local port = nil
local con = nil
local connected = false
local connecting = false
local requests = List.new()
local responses = {}
local queue = 0
local lights = {}
local after_call = nil

local connect

local function sendRequest(request)
  local jsonRequest = cjson.encode(request)
  -- print('sendig: ' .. jsonRequest)
  con:send(jsonRequest)
end

local function getFromQueue()
  if connecting then return false end
  if not connected then
    connect()
    return false
  end
  local r = List.popleft(requests)
  if r == nil then
    queue = 0
    after_call()
  else
    queue = queue + 1
    responses[r.request.id] = r.callback
    sendRequest(r.request)
  end
end

local function printData(data)
  -- print('printing data')
  -- print(cjson.encode(data))
end

local function onReceive(sck, c)
  -- print('received: ' .. c)
  getFromQueue()
  data = cjson.decode(c)
  if responses[data.id] == nil then
    -- print('no callback')
  else
    responses[data.id](data)
    table.remove(responses, data.id)
  end
  after_call()
  -- collectgarbage()
end

local function onReconnected()
  print('reconnected')
  connected = true
  connecting = false
  getFromQueue()
end

local function onConnected()
  print('connected')
  connected = true
  connecting = false
  getFromQueue()
end

local function onDisconnected()
  print('disconnected')
  connected = false
  -- connecting = true
  -- tmr.alarm(5, 3000, 0, function() connect() end)
end

local function onSent(c)
  -- print('sent')
end

local function saveState(data)
  for i, light in ipairs(data.result) do
    lights[light.label] = light
  end
end

connect = function()
  if not connected then
    print('connecting')
    connecting = true
    if (con ~= nil) then con:close() end
    con = net.createConnection(net.TCP, 0)
    con:on('connection', onConnected)
    con:on('reconnection', onReconnected)
    con:on('disconnection', onDisconnected)
    con:on('sent', onSent)
    con:on('receive', onReceive)
    con:connect(port, ip)
  else
    connecting = false
  end
end

function jsonrpc.init(p, i, after)
  ip = i
  port = p
  after_call = after or function() end
  connect()
  -- tmr.alarm(3, 60*1000, 1, function() jsonrpc.getLightState('*') end)
  return con
end

function jsonrpc.getCon()
  return con
end

-- request {id, method, params}
function jsonrpc.send(r, c)
  List.pushright(requests, {['request']=r,['callback']=c})
  if queue <= 0 then
    getFromQueue()
  end
end

function jsonrpc.getLightState(light, callback)
  jsonrpc.send({
    ['method']='get_light_state',
    ['params']={light},
    ['id']=tmr.now(),
    ["jsonrpc"]="2.0"
  },
  function(data)
    saveState(data)
    if callback ~= nil then callback(data) end
  end)
end

-- turn the light on
function jsonrpc.lightOn(light, callback)
  jsonrpc.send({
    ['method']='power_on',
    ['params']={light},
    ['id']=tmr.now(),
    ["jsonrpc"]="2.0"
  }, function(data)
    if lights[light] == nil then
      lights[light] = {}
    end
    if data.result then
      lights[light].power = true
    end
    callback()
  end)
end

-- turn the light off
function jsonrpc.lightOff(light)
  jsonrpc.send({
    ['method']='power_off',
    ['params']={light},
    ['id']=tmr.now(),
    ["jsonrpc"]="2.0"
  }, function(data)
    if lights[light] ~= nil and data.result then
      lights[light].power = false
    end
  end)
end

-- lightsd code, value 0 - 100
function jsonrpc.setBrightness(light, value, trans)
  if lights[light] == nil or not lights[light].power then
    jsonrpc.getLightState(light, function()
      jsonrpc.lightOn(light, function()
        jsonrpc.setBrightness(light, value, trans)
      end)
    end)
    return false
  end
  local l = lights[light]
  local hue = l.hsbk[1]
  local saturation = l.hsbk[2]
  local brightness = (value / 100)
  local temperature = l.hsbk[4]
  local transition = trans or 200
  jsonrpc.send({
    ['method']='set_light_from_hsbk',
    ['params']={light, hue, saturation, brightness, temperature, transition},
    ['id']=tmr.now(),
    ["jsonrpc"]="2.0"
  })
end

return jsonrpc