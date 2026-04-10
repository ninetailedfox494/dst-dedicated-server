local modinfo_path = arg[1]
assert(modinfo_path, "modinfo path required")

local safe_env = {
  ipairs = ipairs,
  pairs = pairs,
  next = next,
  type = type,
  tostring = tostring,
  tonumber = tonumber,
  math = math,
  string = string,
  table = table,
}
local env = setmetatable({}, { __index = safe_env })

local chunk, err = loadfile(modinfo_path, "t", env)
if not chunk then
  io.stderr:write("ERROR: cannot load modinfo: " .. err .. "\n")
  os.exit(1)
end
local ok, run_err = pcall(chunk)
if not ok then
  io.stderr:write("ERROR: cannot execute modinfo: " .. tostring(run_err) .. "\n")
  os.exit(1)
end

local opts = env.configuration_options or {}
local out = {}
for _, opt in ipairs(opts) do
  if type(opt) == "table" and opt.name ~= nil and opt.default ~= nil then
    out[#out + 1] = { name = opt.name, default = opt.default }
  end
end

local function to_lua(v)
  local t = type(v)
  if t == "boolean" or t == "number" then return tostring(v) end
  if t == "string" then return string.format("%q", v) end
  if t == "table" then
    local parts = {}
    for k, vv in pairs(v) do
      local key
      if type(k) == "string" then
        key = "[" .. string.format("%q", k) .. "] = "
      elseif type(k) == "number" then
        key = "[" .. tostring(k) .. "] = "
      else
        error("unsupported table key type: " .. type(k))
      end
      parts[#parts + 1] = key .. to_lua(vv)
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
  end
  error("unsupported default type: " .. t)
end

for _, item in ipairs(out) do
  io.write(string.format("[%q] = %s\n", tostring(item.name), to_lua(item.default)))
end
