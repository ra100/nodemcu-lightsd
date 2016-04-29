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
local func_on_con = nil

local connect

local function sendRequest(request)
  collectgarbage()
  if (node.heap() < 8000) then
    file.open('log.log', 'a+')
    file.writeline('time: '.. tmr.now() .. ' heap: ' .. node.heap())
    file.close()
    node.restart()
  end
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
  else
    queue = queue + 1
    responses[r.request.id] = r.callback
    sendRequest(r.request)
  end
end

local function onReceive(sck, c)
  if DEBUG then print('received: ' .. c) end
  local data = cjson.decode(c)
  if responses[data.id] == nil then
    if DEBUG then print('no callback') end
  else
    responses[data.id](data)
  end
  responses[data.id] = nil
  data = nil
  getFromQueue()
  collectgarbage()
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
  if (func_on_con ~= nil) then
    func_on_con()
    func_on_con = nil
  end
  getFromQueue()
  collectgarbage()
end

local function onDisconnected()
  print('disconnected')
  connected = false
  if not connecting then
    connecting = true
    if (con ~= nil) then con:close() end
    tmr.alarm(3, 1000, 0, connect)
  end
end

local function onSent(c)
  if DEBUG then print('sent') end
end

local function saveState(data)
  for i, light in ipairs(data.result) do
    lights[light.label] = {
      ['power'] = light.power,
      ['hsbk'] = light.hsbk
    }
  end
end

connect = function(callback)
  if (wifi.sta.status() ~= wifi.STA_GOTIP) then
    -- print('WIFI connecting')
    if (wifi.sta.status() ~= wifi.STA_CONNECTING) then
      -- print('reconnecting WIFI')
      wifi.sta.connect()
      wifi.sta.eventMonReg(wifi.STA_GOTIP, connect)
    end
    return false
  end
  if not connected then
    print('connecting')
    connecting = true
    if (con ~= nil) then con:close() tmr.delay(500) end
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

function jsonrpc.init(p, i, l, callback)
  ip = i
  port = p
  if l == nil then l = '*' end
  func_on_con = function() jsonrpc.getLightState(l, callback) end
  if (wifi.sta.status() == wifi.STA_GOTIP) then
    if DEBUG then print("GOT IP") end
    connect()
  else
    if DEBUG then print("Waiting for IP") end
    wifi.sta.eventMonReg(wifi.STA_GOTIP, connect)
  end
  tmr.alarm(3, 3*60*1000, 1, function() jsonrpc.getLightState(l) end)
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
function jsonrpc.lightOn(light)
  if (lights[light] ~= nil and lights[light].power) then
    return true
  end
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
  end)
end

-- turn the light off
function jsonrpc.lightOff(light)
  if (lights[light] ~= nil and not lights[light].power) then
    return true
  end
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
  if (lights[light] == nil) then
    jsonrpc.getLightState(light, function(data)
      jsonrpc.setBrightness(light, value, trans)
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
  if value > 0 then
    jsonrpc.lightOn(light)
  end
end

function jsonrpc.getPause()
  if table.getn(responses) == 0 and queue == 0 then
    return true
  else
    return false
  end
end

function jsonrpc.getQueue()
  return queue
end

return jsonrpc
