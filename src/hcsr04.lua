-- source https://www.esp8266.com/viewtopic.php?f=23&t=9341&start=8

local time_start, time_end, trigger, echo = 0, 0
local sample_count, timer_id

return function(trig_pin, echo_pin, sample_cnt, timer_id, report_cb)
  trigger, echo = trig_pin or 7, echo_pin or 6
  sample_count, timer_id = (sample_cnt + 1) or 4, timer_id or 1

  local total, i, result = 0, 0, {}

  local function echo_cb(level)
    if level == 1 and result[i] == 0 then
      result[i] = -tmr.now()
      gpio.trig(echo, "down")
    elseif level == 0 and result[i] < 0 then
      result[i] = tmr.now() + result[i];
      gpio.trig(echo, "none")
    else
      gpio.trig(echo, "none") -- anything else turn off interrupts and restart at next sample
      if DEBUG then print("DEBUG INT off") end
    end
  end

  local function measure()
    if i > 0 then -- process last sample
      if result[i] < 0 then
        result[i] = 0
        i = i - 1
        return -- skip a beat to allow the sonar to settle down
      else
        total = total + result[i];
      end
      if i == sample_count then
        tmr.unregister(timer_id)
        if DEBUG then
          for j = 1, sample_count do print(("Sample %u is %u"):format(j,result[j])) end
        end
        total = total - result[0] -- substract sample one because it is usually off...
        return report_cb(total / (5820 * (sample_count - 1)))
      end
    end

    gpio.mode(echo, gpio.INT)
    gpio.trig(echo, "up", echo_cb)
    gpio.write(trigger, gpio.HIGH)
    tmr.delay(20)
    gpio.write(trigger, gpio.LOW)
    i = i + 1
  end

  for j = 0, sample_count do result[j] = 0 end -- pre-allocate result array

  gpio.mode(trigger, gpio.OUTPUT)
  tmr.alarm(timer_id, 60, tmr.ALARM_AUTO, measure)
  measure()
end
