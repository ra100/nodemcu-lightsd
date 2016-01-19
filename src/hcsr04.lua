--
--    Copyright (C) 2014 Tamas Szabo <sza2trash@gmail.com>
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

local hcsr04 = {};

function hcsr04.init(pin_trig, pin_echo, average)
	local self = {}
	hcsr04.time_start = 0
	hcsr04.time_end = 0
	hcsr04.trig = pin_trig or 4
	hcsr04.echo = pin_echo or 3
	gpio.mode(hcsr04.trig, gpio.OUTPUT)
	gpio.mode(hcsr04.echo, gpio.INT)
	hcsr04.average = average or 3
end

function hcsr04.echo_cb(level)
	if level == 1 then
		hcsr04.time_start = tmr.now()
		gpio.trig(hcsr04.echo, "down")
	else
		hcsr04.time_end = tmr.now()
	end
end

function hcsr04.measure()
	gpio.trig(hcsr04.echo, "up", hcsr04.echo_cb)
	gpio.write(hcsr04.trig, gpio.HIGH)
	tmr.delay(100)
	gpio.write(hcsr04.trig, gpio.LOW)
	tmr.delay(100000)
	if (hcsr04.time_end - hcsr04.time_start) < 0 then
		return -1
	end
	return (hcsr04.time_end - hcsr04.time_start) / 5800
end

function hcsr04.measure_avg()
	if hcsr04.measure() < 0 then  -- drop the first sample
		return -1 -- if the first sample is invalid, return -1
	end
	avg = 0
	for cnt = 1, hcsr04.average do
		distance = hcsr04.measure()
		if distance < 0 then
			return -1 -- return -1 if any of the meas fails
		end
		avg = avg + distance
		tmr.delay(30000)
	end
	return avg / hcsr04.average
end

return hscr04
