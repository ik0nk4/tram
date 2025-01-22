local json = require('dkjson')


local fileProject = io.open('project.json', 'r')
if not fileProject then
  error('No such file or directory')
  return
end
local stringProject = fileProject:read('*all')
local jsonProject, _, err = json.decode(stringProject, 1, nil)
if err then
  error(err)
end
if not jsonProject then
  error('jsonProject is nil')
  return
elseif not jsonProject.squish then
  error('jsonProject.squish is nil')
end

local squish = jsonProject.squish

local lfs = require('lfs')

local _files = {}

local regexPathFiles = string.format('^%s/', squish.pathFiles)

local PATTERN = {
  MAIN = 'Main "%s"',
  MODULE = 'Module "%s" "%s"',
  OUTPUT = 'Output "%s/%s"'
}

local function isNotIgnoreDir(dirPath)
  for _, value in ipairs(squish.ignoreDirs) do
    if value == dirPath then
      return false
    end
  end
  return true
end

local function attrdir(path)
  for file in lfs.dir(path) do
    if file ~= '.' and file ~= '..' then
      local filePath = path .. '/' .. file
      local fg = filePath:gsub(regexPathFiles, '')
      local attr = lfs.attributes(filePath)
      assert(type(attr) == 'table')
      if file:find('%.lua$') and fg ~= squish.mainFile then
        table.insert(_files, fg)
      end
      if attr.mode == 'directory' and isNotIgnoreDir(fg) then
        attrdir(filePath)
      end
    end
  end
end

local function getFilesInPathFiles(pathFiles)
  attrdir(pathFiles)
  return _files
end

local function convertModulesToSquishFile(fs)
  local modules = {}
  for _, filename in ipairs(fs) do
    local pathRequire = filename
        :gsub('/init%.lua$', ''):gsub('%.lua$', '')
        :gsub('/', '.')
    modules[#modules + 1] = string.format(PATTERN.MODULE, pathRequire, filename)
  end

  local main = string.format(PATTERN.MAIN, squish.mainFile)
  local output = string.format(PATTERN.OUTPUT, squish.outputFolder, squish.outputFile)
  local squishy = string.format(
    '%s\n\n%s\n\n%s',
    main,
    table.concat(modules, '\n'),
    output
  )

  local file = io.open('src/squishy', 'w')
  if not file then
    error('Cant create new file squishy in directory ./src')
  end
  file:write(squishy)
  file:close()
end

local function main()
  local files = getFilesInPathFiles(squish.pathFiles)
  convertModulesToSquishFile(files)
  lfs.mkdir(squish.outputFolder)
end

main()
