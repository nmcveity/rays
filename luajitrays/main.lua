local ffi = require('ffi')

local ffi_cdef = ffi.cdef
local ffi_typeof = ffi.typeof
local ffi_new = ffi.new
local string_char = string.char
local string_format = string.format
local io_write = io.write
local math_random = math.random
local math_ceil = math.ceil
local math_floor = math.floor
local math_sqrt = math.sqrt
local math_min = math.min
local math_max = math.max

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

local fixed_art = {
  "                     ",
  "  1                  ",
  "  1                  ",
  "  1     1   1   11 1 ",
  "  1     1   1  1  1  ",
  "  1     1   1  1  1  ",
  "  1     1   1  1  1  ",
  "  1     1   1  1  1  ",
  "   1111  111 1  11 1"
}

-- Uncomment for Lua logo :)
art = fixed_art

local function object(x, y)
  return {k=x, j=y}
end

ffi_cdef [[
  struct vector_s {
    double x, y, z;
  };
]]

local vector_ct = ffi_typeof('struct vector_s')
local vector = function (x,y,z) 
  local v = vector_ct()
  v.x = x
  v.y = y
  v.z = z
  return v
end

local vdot = function (self, v2)
  return self.x * v2.x + self.y * v2.y + self.z * v2.z
end
local vsqr = function (self)
  return self.x * self.x + self.y * self.y + self.z * self.z
end
local vscale = function (self, t)
  return vector(self.x * t, self.y * t, self.z * t)
end
local vnormalize = function (self)
  return vscale(self, 1 / math_sqrt(vsqr(self)))
end
local vcross = function (self, v2)
  return vector(self.y*v2.z-self.z*v2.y,self.z*v2.x-self.x*v2.z,self.x*v2.y-self.y*v2.x)
end
local vadd = function (self, v2)
  return vector(self.x+v2.x, self.y+v2.y, self.z+v2.z)
end
local vset = function (self, x, y, z)
  self.x, self.y, self.z = x, y, z
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

local seed = math_random(0,10000)
local bxor = bit.bxor
local band = bit.band
local function R()
  seed = seed + seed
  seed = bxor(seed, 1)
  if seed < 0 then
    seed = bxor(seed, 0x88888eef)
  end
  return (seed % 95) / 95
end

local function T(o, d)
  local n = vector(0, 0, 0)
  local t = 1000000000
  local m = 0
  local p = -o.z / d.z
  if 0.01 < p then
    t = p
    vset(n, 0, 0, 1)
    m = 1
  end
  o = vadd(o, vector(0,3,-4))
  for index=1,#objects do -- obj in ipairs(objects) do
    --local p = vadd(o, vector(obj.k, 0, obj.j))
    local p = vector(o.x + objects[index].k, o.y, o.z + objects[index].j)
    local b = vdot(p,d)
    local c = vsqr(p) - 1
    local b2 = b * b
    -- Does the ray hit the sphere?
    if b2 > c then
      local q = b2 - c
      local s = -b - math_sqrt(q)
      if s < t and s > 0.01 then
        t = s
        n = vnormalize(vadd(p, vscale(d, t)))
        m = 2
      end
    end   
  end
  return m, t, n
end

local RED_TILE = vector(3,1,1)
local WHITE_TILE = vector(3,3,3)

local TILES = {
  WHITE_TILE,
  RED_TILE,
}

local function S(o, d)
  local m, t, n = T(o, d)
  if m == 0 then
    -- No sphere found and the ray goes upwards: generate a sky color
    local p = 1 - d.z
    p = p * p
    p = p * p
    return vector(p * 0.7, p * 0.6, p)
  end
  -- A sphere was maybe hit
  local h = vadd(o, vscale(d, t))
  local l = vnormalize(vadd(vector(9+R(), 9+R(), 16), vscale(h,-1)))
  -- Calculate lambertian factor
  local b = vdot(l,n)
  -- Calculate illumination factor
  if b < 0 or T(h, l) ~= 0 then
    b = 0
  end
  if m == 1 then
    local h2 = vscale(h,0.2)
    return vscale(TILES[band((math_ceil(h2.x) + math_ceil(h2.y)),1)+1], b * 0.2 + 0.1)
  end
  local r = vadd(d, vscale(n, vdot(n, vscale(d, -2))))
  -- Calculate the color 'p' with diffuse and specular component
  local s = 0
  if b > 0 then
    s = 1
  end
  -- Note to self: removing branch above (code below) did not improve times
  --local s = math_max(0, math_min(1, math_ceil(b)))
  local p = vdot(l, vscale(r,s))
  local p33 = p * p
  p33 = p33 * p33
  p33 = p33 * p33
  p33 = p33 * p33
  p33 = p33 * p33
  p33 = p33 * p
  p = p33 * p33 * p33
  return vadd(vector(p,p,p), vscale(S(h,r), 0.5))
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

local g = vnormalize(vector(-5.5, -16, 0))
local a = vscale(vnormalize(vcross(vector(0,0,1), g)), 0.002)
local b = vscale(vnormalize(vcross(g,a)), 0.002)
local c = vadd(vscale(vadd(a,b), -256), g)

local offset = 1
local jump = 1

local RAYS = 64
local SCALE = 64 / RAYS
local out = ffi_new('char[?]', w*h*3)
local i = 0

local CAM_POS = vector(17,16,8)

for y=h-1,0,-1 do
  for x=w-1,0,-1 do
    local p = vector(13,13,13)
    -- Cast 64 rays per pixel
    for r=1,RAYS do
      local t = vadd(vscale(vscale(a, R()-0.5), 99), vscale(vscale(b,R()-0.5), 99))
      local ra = vscale(a, R()+x)
      local rb = vscale(b, R()+y)
      local d = vnormalize(vadd(vscale(t, -1), vscale(vadd(vadd(ra, rb), c), 16)))
      p = vadd(vscale(S(vadd(CAM_POS, t), d), 3.5*SCALE), p)
    end
    out[i] = p.x
    out[i+1] = p.y
    out[i+2] = p.z
    i = i + 3
  end
end

local header = string_format("P6 %d %d 255 ", w, h)
ffi.cdef("size_t fwrite ( const void * ptr, size_t size, size_t count, struct FILE * stream );")
ffi.C.fwrite(header, 1, #header, io.stdout)
ffi.C.fwrite(out, 1, w*h*3, io.stdout)
