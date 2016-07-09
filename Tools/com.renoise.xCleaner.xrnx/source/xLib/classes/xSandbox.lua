--[[============================================================================
xSandbox
============================================================================]]--

--[[--

xSandbox allows you to execute code in a controlled environment
.
#

## How to use

    -- create instance 
    sandbox = xSandbox()

    -- supply function
    sandbox.callback_str = 
      "print('hello world')"

    -- and call it...
    sandback.callback()


## Arguments and return values

    -- if you need to supply arguments and define return value, 
    -- one approach is to define a 'prefix' and 'suffix' 
    -- (always added to the generated code)

    -- define arguments 
    sandbox.str_prefix = "local some_arg = select(1, ...)"
    
    -- define return value
    sandbox.str_suffix = "return some_arg"
      
    -- supply function
    sandbox.callback_str = 
      "some_arg = some_arg + 'foo'"..
      "print(some_arg)"

    -- now call the function like this:
    local result = sandback.callback('my_arg')


## Custom properties

TODO how to ... 

]]

class 'xSandbox'

-- disallow the following lua methods/properties
xSandbox.UNTRUSTED = {
  "collectgarbage",
  "coroutine",
  "dofile",
  "io",
  "load",
  "loadfile",
  "module",
  "os",
  "setfenv",
  "class",
  "rawset",
  "rawget",
}

function xSandbox:__init()


  --- function, compiled function (when set, always valid)
  self.callback = nil

  --- string, code to insert into all generated functions
  self.str_prefix = ""
  self.str_suffix = "return"

  --- boolean, set to true for instant compilation of callback string
  self.compile_at_once = true

  --- string, text representation of the function 
  self.callback_str = property(self.get_callback_str,self.set_callback_str)
  self.callback_str_observable = renoise.Document.ObservableString("")

  --- properties can contain custom get/set methods
  self.properties = property(self.get_properties,self.set_properties)
  self._properties = {}

  --- invoked when callback has changed
  self.modified_observable = renoise.Document.ObservableBang()

  --- table, sandbox environment
  self.env = nil

  -- initialize --

  local env = {
    assert = _G.assert,
    error = _G.error,
    ipairs = _G.ipairs,
    loadstring = _G.loadstring,
    math = _G.math,
    next = _G.next,
    pairs = _G.pairs,
    print = _G.print,
    pcall = _G.pcall,
    select = _G.select,
    string = _G.string,
    table = _G.table,
    tonumber = _G.tonumber,
    tostring = _G.tostring,
    type = _G.type,
    unpack = _G.unpack,
    -- renoise extended
    ripairs = _G.ripairs,
    rprint = _G.rprint,
    oprint = _G.oprint,
  }

  self.env = env
  env = {}

  -- metatable (constants and shorthands)
  setmetatable(self.env,{
    __index = function (t,k)
      --print("*** sandbox access ",k)
      if table.find(xSandbox.UNTRUSTED,k) then
        error("Property or method is not allowed:"..k)
      else
        if self.properties[k] and self.properties[k].access then
          return self.properties[k].access(env)
        else
          return env[k]
        end
      end
    end,
    __newindex = function (t,k,v)
      --print("*** sandbox assign ",k,v)
      if self.properties[k] and self.properties[k].assign then
        self.properties[k].assign(env,v)
      else
        env[k] = v
      end

    end,
    __metatable = false -- prevent tampering
  })


end

--==============================================================================
-- Getter/Setter Methods
--==============================================================================

function xSandbox:get_callback_str()
  --TRACE("xSandbox:get_callback_str - ",self.callback_str_observable.value)
  return self.callback_str_observable.value
end

-- it's recommended to call test_syntax before setting this value,
--  otherwise you get no feedback if it failed

function xSandbox:set_callback_str(str_fn)
  TRACE("xSandbox:set_callback_str(str_fn)",#str_fn)

  assert(type(str_fn) == "string", "Expected string as parameter")

  local modified = (str_fn ~= self.callback_str_observable.value)

  local str_combined = self:prepare_callback(str_fn)
  local passed,err = self:test_syntax(str_combined)
  
  self.callback_str_observable.value = str_fn

  if not err and self.compile_at_once then
    local passed,err = self:compile()
    if not passed then -- should not happen! 
      LOG(err)
    end
  else
    LOG(err)
  end

  if modified then
    self.modified_observable:bang()
  end

end

-------------------------------------------------------------------------------

function xSandbox:get_properties()
  return self._properties
end

function xSandbox:set_properties(val)
  assert(type(val) == "table", "Expected table as parameter")
  self._properties = val
end


--==============================================================================
-- Class Methods
--==============================================================================
-- wrap callback in function with variable run-time arguments 
-- @param str_fn (string) function as string

function xSandbox:prepare_callback(str_fn)
  --TRACE("xSandbox:prepare_callback(str_fn)",#str_fn)

  assert(type(str_fn) == "string", "Expected string as parameter")

  local str_combined = [[return function(...)
  ]]..self.str_prefix..[[
  ]]..str_fn..[[
  ]]..self.str_suffix..[[
  end]]

  return str_combined

end


-------------------------------------------------------------------------------
-- call method to evaluate function (ensure that it's safe to run)
-- @return boolean, true when method passed
-- @return string, error message when failed

function xSandbox:compile()

  if (self.callback_str == "") then
    LOG("xSandbox: no function was provided")
    return true
  end

  local str_combined = self:prepare_callback(self.callback_str)
  local def = loadstring(str_combined)
  self.callback = def()
  setfenv(self.callback, self.env)

  return true

end

-------------------------------------------------------------------------------
-- nested block comments/longstrings are depricated and will fail

function xSandbox.contains_comment_blocks(str)
  TRACE("xSandbox.contains_comment_blocks(str)")

  if string.find(str,"%[%[") then
    return true
  elseif string.find(str,"%]%]") then
    return true
  else
    return false
  end

end


-------------------------------------------------------------------------------
-- check for syntax errors
--  (assert provides better error messages)
-- @param str_fn (string) function as string
-- @return boolean, true when passed
-- @return string, when failed

function xSandbox:test_syntax(str_fn)
  TRACE("xSandbox:test_syntax(str_fn)",str_fn)

  local function untrusted_fn()
    assert(loadstring(str_fn))
  end
  setfenv(untrusted_fn, self.env)
  local pass,err = pcall(untrusted_fn)
  if not pass then
    return false,err
  end

  return true

end

-------------------------------------------------------------------------------
-- strip code comments from a string
-- @param str_fn (string)
-- @return string

function xSandbox.strip_comments(str_fn)
  TRACE("xSandbox.strip_comments(str_fn)",str_fn)

  local t = xLib.split(str_fn,"\n")
  for k,v in ripairs(t) do
    local ln = xLib.trim(v)
    if (ln:sub(0,2) == "--") then 
      table.remove(t,k)
    end
  end
  return table.concat(t,"\n")

end

-------------------------------------------------------------------------------
-- check if a given string consists of comments only
-- @param str_fn (string)
-- @return bool

function xSandbox.contains_code(str_fn)
  TRACE("xSandbox.contains_code(str_fn)",str_fn)

  return string.match(xSandbox.strip_comments(str_fn),"%a") and true or false

end

-------------------------------------------------------------------------------
-- automatically insert a return statement into a code snippet
-- step 1: detect if return statement is present

function xSandbox.insert_return(str_fn)
  TRACE("xSandbox.insert_return(str_fn)",str_fn)
  
  local present = false
  local t = xLib.split(str_fn,"\n")
  for k,v in ipairs(t) do
    if not present then
      local ln = xLib.trim(v)
      --print("ln",ln)
      
      if (ln ~= "") then -- skip empty lines
        if (ln:sub(0,2) ~= "--") then -- skip initial comment blocks
          if (ln ~= "-") then -- single minus (can be the result
            -- of commenting out, live coding style...)
            present = true
            -- only insert if not already present
            if (ln:sub(0,6) ~= "return") then
              t[k] = ("return %s"):format(ln)
            end
          end
        end
      end

    end
  end

  --print(">>> insert_return t",rprint(t))

  return table.concat(t,"\n")

end

-------------------------------------------------------------------------------
-- "safer" renaming of a string token (for example, a variable name)
-- @param str_fn (string), the function text 
-- @param old_name (string)
-- @param new_name (string)
-- @param prefix (string), prepend to old/new name when defined

function xSandbox.rename_string_token(str_fn,old_name,new_name,prefix)

  local str_search = prefix and prefix..old_name or old_name
  local str_replace = prefix and prefix..new_name or new_name
  local str_patt = "(.?)("..str_search..")([^%w])"
  str_fn = string.gsub(str_fn,str_patt,function(...)
    local c1,c2,c3 = select(1,...),select(2,...),select(3,...)
    --print("c1,c2,c3",c1,c2,c3)
    local patt = "[%w_]" 
    if string.match(c1,patt) or string.match(c3,patt) then
      return c1..c2..c3
    end
    return c1..str_replace..c3
  end)

  return str_fn

end

