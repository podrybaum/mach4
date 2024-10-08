xc = require("xc")

local function populateAPI(t)
  local api = {}
  for k,v in pairs(t) do
    api[k] = {
      type = (type(v) == "function" and "function" or "value"),
      description = "",
      returns = "",
    }
  end
  return api
end


  xc = {
    type = "lib",
    description = "Xbox controller library",
    childs = populateAPI(xc),
  }

for child in pairs(xc["childs"]) do
	print(child)
end



