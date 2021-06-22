local function div0(a, b)
  if b == 0 then
    error("DIV BY ZERO !")
  else
    return a / b
  end
end

local function div1(a, b) return div0(a, b) end
local function div2(a, b) return div1(a, b) end

local ok, result = pcall(div2, 4, 2); print(ok, result)
local ok, err = pcall(div2, 5, 0);    print(ok, err)
local ok, err = pcall(div2, {}, {});  print(ok, err)