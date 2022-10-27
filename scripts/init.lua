local IS_WINDOWS = package.config:sub(1, 1) == '\\'

local function rm(path)
  if IS_WINDOWS then
    os.execute('cmd /q /c del ' .. path:gsub('/', '\\'))
  else
    os.execute('rm -f ' .. path)
  end
end

local function read(filename)
  local f, e1 = io.open(filename, 'rb')
  if e1 then
    error(e1)
  end

  local text, e2 = f:read('a')
  f:close()
  if e2 then
    error(e2)
  end

  return text
end

local function write(filename, text)
  local f, e1 = io.open(filename, 'wb')
  if e1  then
    error(e1)
  end

  local _, e2 = f:write(text)
  f:close()
  if e2 then
    error(e2)
  end
end

local function sed(text, replacements)
  return (text:gsub('@([%a_]+)@', replacements))
end

local function sed_file(src, dst, replacements)
  if type(dst) == 'table' then
    replacements, dst = dst, nil
  end
  if not dst then
    dst = src
  end
  local text = read(src)
  text = sed(text, replacements)
  write(dst, text)
end

local function execute(cmd)
  if IS_WINDOWS then
    cmd = cmd:gsub('/', '\\')
  end

  local out_tmpfile = os.tmpname()
  local err_tmpfile = os.tmpname()
  local cmd_line = ('%s >%s 2>%s'):format(cmd, out_tmpfile, err_tmpfile)
  os.execute(cmd_line)

  local std_out = read(out_tmpfile)
  os.remove(out_tmpfile)
  std_out = std_out:match('^(.-)%s*$')

  local std_err = read(err_tmpfile)
  os.remove(err_tmpfile)
  std_err = std_err:match('^(.-)%s*$')

  if #std_err > 0 then
    error(std_err)
  end

  return std_out
end

local remotes = execute 'git remote -v'
local gh_user, gh_repo = remotes:match('github%.com:([^/]+)/([^/]+)%s+%(fetch')
local author_name = execute 'git config user.name'
local author_email = execute 'git config user.email'
local rock_name = (gh_repo:match('^(.-)%.git$')) or gh_repo
local rock_summary = "Another Lua library"
local module_name

local conf

while true do

  local function prompt(message, default)
    io.write(message)
    if default ~= nil then
      io.write(' [', tostring(default), ']')
    end
    io.write(': ')
    local line = io.read('l')
    return #line > 0 and line or default
  end

  rock_name = prompt("Rock's name", rock_name)
  rock_summary = prompt("Rock's summary", rock_summary)
  author_name = prompt("Author's full name", author_name)
  author_email = prompt("Author's email address", author_email)

  module_name = rock_name:match('^(.-)%.lua$')
  if not module_name then
    module_name = rock_name
  end

  conf = {
    ROCK_NAME = rock_name,
    ROCK_SUMMARY = rock_summary or ('%s is a Lua module.'):format(rock_name),
    AUTHOR_NAME = author_name,
    AUTHOR_EMAIL = author_email,
    GH_USER = gh_user,
    GH_REPO = gh_repo,
    MODULE_NAME = module_name
  }

  print(sed([[
The module will be initialized with:

GitHub:
- User          : @GH_USER@
- Repository    : @GH_REPO@

Rock:
- Name          : @ROCK_NAME
- Summary       : @ROCK_SUMMARY@
- Author        : @AUTHOR_NAME@
- Author's email: @AUTHOR_EMAIL@

Module
- Name          : @MODULE_NAME@
]], conf))

  local answer = prompt("Is this correct? (Yn)", 'Y')
  if answer == 'Y' then
    break
  end

  print('\x1bc')
end

sed_file('.chglog/config.yml', conf)
sed_file('build-aux/config.ld', conf)
sed_file('Makefile', conf)
sed_file('README.md.in', 'README.md', conf)
sed_file('LICENSE.txt', conf)
sed_file('rockspecs/rockspec.in', ('rockspecs/%s-dev-1.rockspec'):format(rock_name), conf)

rm('README.md.in')
rm('rockspecs/rockspec.in')
rm('scripts/init.lua')
