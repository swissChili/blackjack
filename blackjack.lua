-- blackjack.lua
-- Copyright (c) 2020 swissChili <swisschili.sh> all rights reserved.

function htmlProcessor(site, template, parameters)
  local parent = ""
  -- #{ key = value }
  template = template:gsub("#{%s*([%w._]+)%s*=%s*([%w._]+)%s*}",
    function(k, v)
      if (k == "parent")
      then
        parent = v
      else
        parameters[k] = v
      end
      return ""
    end
  )

  -- ${ variable }
  template = template:gsub("%${%s*([%w_%.]+)%s*}", function (word)
    return parameters[word]
  end)

  if parent ~= "" then
    parameters["body"] = template
    return site:renderTemplate(parent, parameters)
  end

  return template
end

function mdProcessor(site, temp, parameters)
  local toReplace = {
    { "`", "code" },
    { "%*%*", "b" },
    { "%*", "i" },
    { "~~", "s" }
  }

  local parent = ""
  -- @ must be at start of a line, so adding \n makes it work at
  -- the start of a file.
  local template = '\n' .. temp
  -- @key = value
  template = template:gsub("\n%s*@([%w%._]+)%s*=%s*([%w%._]+)",
    function (k, v)
      if k == "parent" then
        parent = v
      else
        parameters[k] = v
        print(k .. ' = ' .. v)
      end

      return ''
    end
  )

  template = template:gsub("%${%s*([%w_%.]+)%s*}", function (word)
    return parameters[word]
  end)

  template = template:gsub("(#+)([^=.^\n]+)\n", function (depth, header)
    return "<h" .. #depth .. ">" .. header .. "</h" .. #depth .. ">"
  end)

  template = template:gsub("```\n+(.-)\n+```", function (code)
    return "<pre><code class>" .. code .. '</code></pre>'
  end)

  for i = 1, #toReplace do
    local k = toReplace[i][1]
    local v = toReplace[i][2]
    template = template:gsub(k .. "(.-)" .. k, function (body)
      return "<" .. v .. ">" .. body .. "</" .. v .. ">"
    end)
  end

  template = template:match( "^%s*(.-)%s*$"):gsub("\n\n+", "\n<br>\n")

  if parent ~= "" then
    parameters["body"] = template
    return site:renderTemplate(parent, parameters)
  end

  return template
end

CommandProcessor = {
  command = "",
  parent = nil,
}

function CommandProcessor:new(command)
  cmdp = {}
  setmetatable(cmdp, self)
  self.__index = self
  cmdp.command = command
  return cmdp
end

function cmdProcessor(command)
  return function (site, template, parameters)
    local p = io.popen(command .. ' > /tmp/blackjack-stdout.html', 'w')
    p:write(template)
    p:close()
    local output = io.open("/tmp/blackjack-stdout.html", "r")
    if output ~= nil then
      local out = output:read("all")
      output:close()
      return out
    else
      print("    Error: Could not read from temporary file.")
      os.exit(1)
    end
  end
end

Site = {
  -- Template source directory
  templates = "templates",
  -- Content source directory
  content = "content",
  -- Output directory
  output = "site",
  -- Static file directory
  static = nil,
  -- File processor objects
  processors = {
    html = {
      process = htmlProcessor,
      extension = 'html'
    },
    md = {
      process = mdProcessor,
      extension = 'html'
    }
  },
  -- Global config data
  global = {}
}

local function getExtension(file)
  return file:match(".(%w+)$")
end

function Site:renderTemplate(templateFile, body)
  local fp = self.templates .. '/' .. templateFile
  return self:render(fp, body)
end

function Site:render(fp, body)
  local f = io.open(fp, "r")
  if f ~= nil then
    local text = f:read("all")
    f:close()
    local extension = getExtension(fp)
    if self.processors[extension] ~= nil then
      return self.processors[extension].process(self, text, body)
    else
      -- print("    Error: There is no processor for ." .. extension .. " files")
      -- os.exit(1)
      return text
    end
  else
    print("    Error: Tried to open template that does not exist")
    print(fp)
    os.exit(1)
  end
end

local function replaceExtension(file, ext)
  return file:gsub(".%w+$", '.' .. ext)
end

local function getFileName(site, file)
  return file:sub(#site.content + 1)
end

function Site:build()
  local p = io.popen('find "'.. self.content ..'" -type f')
  for file in p:lines() do
    print(" Building: ".. file)
    local html = self:render(file, self.global)
    local outFile = self.output .. getFileName(
      self,
      replaceExtension(file, self.processors[getExtension(file)].extension)
    )
    print("  Writing: " .. outFile)
    local file = io.open(outFile, "w")
    if file ~= nil then
      file:write(html)
    else
      print("    Error: Could not write file. Does "
        .. self.output .. " directory exist?")
      os.exit(1)
    end
  end

  if self.static ~= nil then
    print("  Copying: " .. self.static)
    io.popen('cp -r "' .. self.static .. '" "' .. self.output .. '/static/"')
  end
end
