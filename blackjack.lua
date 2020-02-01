-- blackjack.lua
-- Copyright (c) 2020 swissChili <swisschili.sh> all rights reserved.

-- Class that processes HTML files
HtmlProcessor = {}

function HtmlProcessor:process(site, template, parameters)
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

LmlProcessor = {}

function LmlProcessor:process(site, template, parameters)
  local parent = ""
  -- @ must be at start of a line, so adding \n makes it work at
  -- the start of a file.
  template = '\n' .. template
  -- @key = value
  template = template:gsub("\n%s*@([%w%._]+)%s*=%s*([%w%._]+)",
    function (k, v)
      if k == "parent" then
        parent = v
      else
        parameters[k] = v
      end

      return ''
    end
  )

  template = template:gsub("(#+)([^=.^\n]+)\n", function (depth, header)
    return "<h" .. #depth .. ">" .. header .. "</h" .. #depth .. ">"
  end)

  template = template:gsub("%*%*(.-)%*%*", function (bold)
    return "<b>" .. bold .. "</b>"
  end)

  template = template:gsub("%*(.-)%*", function (it)
    return "<i>" .. it .. "</i>"
  end)

  template = template:gsub("%${%s*([%w_%.]+)%s*}", function (word)
    return parameters[word]
  end)

  template = template:match( "^%s*(.-)%s*$"):gsub("\n\n+", "\n<br>\n")

  if parent ~= "" then
    parameters["body"] = template
    return site:renderTemplate(parent, parameters)
  end

  return template
end

Site = {
  -- Template source directory
  templates = "templates",
  -- Content source directory
  content = "content",
  -- Output directory
  output = "site",
  -- Static file directory
  static = "static",
  -- File processor objects
  processors = {
    html = HtmlProcessor,
    lml = LmlProcessor
  }
}

function Site:renderTemplate(templateFile, body)
  local fp = self.templates .. '/' .. templateFile
  return self:render(fp, body)
end

function Site:render(fp, body)
  local f = io.open(fp, "r")
  if f ~= nil then
    local text = f:read("all")
    f:close()
    local extension = fp:match(".(%w+)$")
    return self.processors[extension]:process(self, text, body)
  else
    print("    Error: Tried to open template that does not exist")
    print(fp)
    os.exit(1)
  end
end

local function replaceExtension(file, ext)
  return file:gsub(".%w+$", '.' .. ext)
end

local function getFileName(file)
  return file:match("/([^/]+)$")
end

function Site:build()
  local p = io.popen('find "'.. self.content ..'" -type f')
  for file in p:lines() do
    print(" Building: ".. file)
    local html = self:render(file, {})
    local outFile = self.output .. '/' .. getFileName(
      replaceExtension(file, 'html')
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

  print("  Copying: " .. self.static)
  io.popen('cp -r "' .. self.static .. '" "' .. self.output .. '/static/"')
end
