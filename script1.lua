local script1 = {}

function script1.init()
  print('script1.init!')
end

function script1.loop(elapsed, key)
  io.write(('script1.loop() elapsed = %g key = %d\n\r'):format(elapsed, key))
  --print('script1.loop!')
end

return script1
