dofile('config.lua')
dofile('wifi.lua')

files = file.list()

-- file.remove('jsonrpc.lc')
-- file.remove('hcsr04.lc')
-- file.remove('control.lc')
-- file.remove('list.lc')
if (files['jsonrpc.lc'] == nil) then node.compile('jsonrpc.lua') end
if (files['hcsr04.lc'] == nil) then node.compile('hcsr04.lua') end
if (files['control.lc'] == nil) then node.compile('control.lua') end
if (files['list.lc'] == nil) then node.compile('list.lua') end

dofile('control.lc')