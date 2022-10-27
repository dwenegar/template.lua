local IS_WINDOWS = package.config:sub(1, 1) == '\\'

local function run(source, destination)
  local cmd = IS_WINDOWS
    and 'cmd /c copy /b /y %s %s'
    or 'cp %s %s'
  if IS_WINDOWS then
    source = source:gsub('/', '\\')
    destination = destination:gsub('/', '\\')
  end
  cmd = cmd:format(source, destination)
  print(('Executing `%s`'):format(cmd))
  os.execute(cmd)
end

run(...)
