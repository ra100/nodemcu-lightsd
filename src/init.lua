dofile('config.lua')

-- function compile_remove(f)
--   node.compile(f)
--   file.remove(f)
-- end

-- local files = {
--   'wifi.lua',
--   'lifx.lua',
--   'hcsr04.lua',
--   'control.lua'
-- }

-- local filelist = file.list()

-- for i,f in ipairs(files) do
--   if (filelist[f]) then
--     print('compiling ' .. f)
--     compile_remove(f)
--   end
-- end

dofile('control.lua')
dofile('wifi.lua')
