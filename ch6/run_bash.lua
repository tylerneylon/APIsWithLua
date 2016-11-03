print('Here are the global tables defined:')
for k, v in pairs(_G) do
  if type(v) == 'table' then
    print('  ' .. k)
  end
end

if os then
  print('Hit control-D to exit this subshell.')
  os.execute('bash')
else
  print('I could not run bash.')
end
