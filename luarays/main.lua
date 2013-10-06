
local string_char = string.char
local io_write = io.write
local math_random = math.random
local math_ceil = math.ceil
local math_floor = math.floor
local math_sqrt = math.sqrt

local art = {
  "                   ",
  "    1111           ",
  "   1    1          ",
  "  1           11   ",
  "  1          1  1  ",
  "  1     11  1    1 ",
  "  1      1  1    1 ",
  "   1     1   1  1  ",
  "    11111     11   "
}

local function object(x, y)
  return {k=x, j=y}
end

local vector
local vector_meta = {
  __index = {
    dot = function (self, v2)
      return self.x * v2.x + self.y * v2.y + self.z * v2.z
    end,
    normalize = function (self)
      return self:scale(1 / math.sqrt(self:dot(self)))
    end,
    scale = function (self, t)
      return vector(self.x * t, self.y * t, self.z * t)
    end,
    cross = function (self, v2)
      return vector(self.y*v2.z-self.z*v2.y,self.z*v2.x-self.x*v2.z,self.x*v2.y-self.y*v2.x)
    end,
    add = function (self, v2)
      return vector(self.x+v2.x, self.y+v2.y, self.z+v2.z)
    end,
    set = function (self, x, y, z)
      self.x, self.y, self.z = x, y, z
    end
  }
}

function vector(x, y, z)
  local v = {x = x or 0, y = y or 0, z = z or 0}
  setmetatable(v, vector_meta)
  return v
end

local objects = {}

local function F() 
  local nr = #art
  local nc = #art[1]
  for k = nc,1,-1 do
    for j = nr,1,-1 do
      if art[j]:sub(nc-k+1, nc-k+1) ~= ' ' then
        objects[#objects+1] = object(-k+1, -(nr - j))
      end
    end
  end
end

local function R()
  return math_random()
end

--The intersection test for line [o,v].
-- Return 2 if a hit was found (and also return distance t and bouncing ray n).
-- Return 0 if no hit was found but ray goes upward
-- Return 1 if no hit was found but ray goes downward

local function T(o, d)
  local n = vector()
  local t = 1000000000
  local m = 0
  local p = -o.z / d.z
  if 0.01 < p then
    t = p
    n:set(0, 0, 1)
    m = 1
  end
  o = o:add(vector(0,3,-4))
  for index, obj in ipairs(objects) do
    local p = o:add(vector(obj.k, 0, obj.j))
    local b = p:dot(d)
    local c = p:dot(p) - 1
    local b2 = b * b
    -- Does the ray hit the sphere?
    if b2 > c then
      local q = b2 - c
      local s = -b - math_sqrt(q)
      if s < t and s > 0.01 then
        t = s
        n = p:add(d:scale(t)):normalize()
        m = 2
      end
    end   
  end
  return m, t, n
end

local function S(o, d)
  local m, t, n  = T(o, d)
  local on = vector(n.x, n.y, n.z)
  if m == 0 then
    -- No sphere found and the ray goes upwards: generate a sky color
    local p = 1 - d.z
    p = p * p
    p = p * p
    return vector(p * 0.7, p * 0.6, p)
  end
  -- A sphere was maybe hit
  local h = o:add(d:scale(t))
  local l = vector(9+R(), 9+R(), 16):add(h:scale(-1)):normalize()
  -- Calculate lambertian factor
  local b = l:dot(n)
  -- Calculate illumination factor
  if b < 0 or T(h, l, t, n) ~= 0 then
    b = 0
  end
  if m == 1 then
    h = h:scale(0.2)
    if ((math_ceil(h.x) + math_ceil(h.y)) % 2) == 1 then
      return vector(3,1,1):scale(b * 0.2 + 0.1)
    else
      return vector(3,3,3):scale(b * 0.2 + 0.1)
    end
  end
  local r = d:add(on:scale(on:dot(d:scale(-2))))
  -- Calculate the color 'p' with diffuse and specular component
  local s = 0
  if b > 0 then
    s = 1
  end
  local p = l:dot(r:scale(s))
  local p33 = p * p
  p33 = p33 * p33
  p33 = p33 * p33
  p33 = p33 * p33
  p33 = p33 * p33
  p33 = p33 * p
  p = p33 * p33 * p33
  return vector(p,p,p):add(S(h,r):scale(0.5))
end

F()

local w, h = 512, 512
local argv = arg

if #argv > 0 then
  w = tonumber(argv[1])
end
if #argv > 1 then
  h = tonumber(argv[2])
end

io.write(string.format("P6 %d %d 255 ", w, h))
local g = vector(-5.5, -16, 0):normalize()
local a = vector(0,0,1):cross(g):normalize():scale(0.002)
local b = g:cross(a):normalize():scale(0.002)
local c = a:add(b):scale(-256):add(g)

--[[
0.001891 -0.000650 0.000000
0.000000 0.000000 0.002000
-0.325080 -0.945686 0.000000
-0.809271 -0.779246 -0.512000

]]

local offset = 1
local jump = 1

local function clamp(x)
  if x < 1 then
    return 1
  elseif x > 255 then
    return 255
  else
    return math_floor(x)
  end
end

local RAYS = 64
local SCALE = 64 / RAYS

for y=h-1,0,-1 do
  for x=w-1,0,-1 do
    local p = vector(13,13,13)
    -- Cast 64 rays per pixel

    for r=1,RAYS do
      local t = a:scale(R()-0.5):scale(99):add(b:scale(R()-0.5):scale(99))
      local ra = a:scale(R()+x)
      local rb = b:scale(R()+y)
      local d = t:scale(-1):add(ra:add(rb):add(c):scale(16)):normalize()
      p = S(vector(17,16,8):add(t), d):scale(3.5*SCALE):add(p)
    end
    io_write(string_char(clamp(p.x)), 
      string_char(clamp(p.y)),
      string_char(clamp(p.z)))
  end
end
