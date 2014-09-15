
local RichLabel = class("RichLabel", function()
    local node = display.newNode()
    return node
end)	

RichLabel.__index      = RichLabel
RichLabel._fontName = nil
RichLabel._fontSize = nil
RichLabel._fontColor = nil

--目前支持参数
--[[
	文字 
	fontName  : font name
	fontSize  : number
	fontColor : ccc3(r,g,b)

	图片
	image : "xxx.png"
	scale : number
]]--

function RichLabel:create(params)
	local ret = RichLabel.new()
	ret:init(params)
	return ret
end

function RichLabel:init(params)
	local text = params.text
	local fontName = params.fontName or "Arial"
	local fontSize = params.fontSize or 30
	local fontColor = params.fontColor or ccc3(255, 255, 255)
	local dimensions = params.dimensions or CCSize(0, 0) --默认无限扩展

	do --test
		local bgSprite = CCSprite:createWithTexture(nil, CCRect(0, 0, dimensions.width, dimensions.height))
		bgSprite:setAnchorPoint(ccp(0, 1))
		bgSprite:setColor(ccc3(255, 0, 0))
		self:addChild(bgSprite)
	end

    self._fontName = fontName
    self._fontSize = fontSize
    self._fontColor = fontColor

	--转化好的数组
	local parseArray = self:parseString(text)

	--将字符串拆分成一个个字符
	self:formatString(parseArray)

	dump(parseArray)

	--创建精灵
	local spriteArray = self:createSprite(parseArray)

	--调整精灵位置
	self:adjustPosition(spriteArray, dimensions)

	--test
	self:setPosition(display.cx - 200, display.cy)

end

function RichLabel:adjustPosition(spriteArray, dimensions)
	local totalWidth = dimensions.width
	local totalHight = dimensions.height

	local widthArr = {} --宽度数组
	local heightArr = {} --高度数组

	local spriteNum = #spriteArray

	--精灵的大小
	for i, sprite in ipairs(spriteArray) do
		local contentSize = sprite:getContentSize()
		widthArr[i] = contentSize.width
		heightArr[i] = contentSize.height
	end

	--从左往右，从上往下拓展
	local curX = 0
	
	local curIndexX = 1
	local curIndexY = 1
	
	local pointArrX = {} --每个精灵的x坐标
	local rowIndexArr = {} --行数组，以行为index储存精灵组
	local indexArrY = {}

	--计算宽度，并自动换行
	for i, spriteWidth in ipairs(widthArr) do
		local nexX = curX + spriteWidth
		local pointX
		local rowIndex = curIndexY

		local halfWidth = spriteWidth * 0.5
		if nexX > totalWidth and totalWidth ~= 0 then --超出界限了
			pointX = halfWidth
			if curIndexX == 1 then --当前是第一个，
				curX = 0-- 重置x
			else --不是第一个，当前行已经不足容纳
				rowIndex = curIndexY + 1 --换行
				curX = spriteWidth
			end
			curIndexX = 1 --x坐标重置
			curIndexY = curIndexY + 1 --y坐标自增
		else
			pointX = curX + halfWidth
			curX = pointX + halfWidth
			curIndexX = curIndexX + 1
		end
		pointArrX[i] = pointX --保存每个精灵的x坐标

		indexArrY[i] = rowIndex --保存每个精灵的行

		local tmpIndexArr = rowIndexArr[rowIndex]

		if not tmpIndexArr then --没有就创建
			tmpIndexArr = {}
			rowIndexArr[rowIndex] = tmpIndexArr
		end
		tmpIndexArr[#tmpIndexArr + 1] = i
	end

	-- dump(rowIndexArr)

	local curY = 0
	local pointArrY = {} --每一行的y坐标

	--计算每一行的高度
	for i, rowInfo in ipairs(rowIndexArr) do
		local maxHeight = 0
		for j, index in ipairs(rowInfo) do
			local height = heightArr[index]
			if height > maxHeight then
				maxHeight = height
			end
		end
		local pointY = curY + maxHeight * 0.5
		pointArrY[#pointArrY + 1] = pointY
		curY = curY + maxHeight
	end

	-- dump(pointArrY)

	--设置坐标
	for i, sprite in ipairs(spriteArray) do
		local pointX = pointArrX[i] --x坐标是直接读取
		local indexY = indexArrY[i] --y坐标是先读取精灵的行，然后再找出该行对应的坐标
		local pointY = pointArrY[indexY]
		sprite:setPosition(pointX, -pointY)
	end

end
  
function RichLabel:createSprite(parseArray)
	local spriteArray = {}

	for i, dic in ipairs(parseArray) do
		local textArr = dic.textArray
		if #textArr > 0 then --创建文字
			local fontName = dic.fontName or self._fontName
			local fontSize = dic.fontSize or self._fontSize
			local fontColor = dic.color or self._fontColor
			for j, word in ipairs(textArr) do
				local label = CCLabelTTF:create(word, fontName, fontSize)
				label:setColor(fontColor)
				spriteArray[#spriteArray + 1] = label
				self:addChild(label)
			end
		elseif dic.image then
			local sprite = CCSprite:create(dic.image)
			local scale = dic.scale or 1
			sprite:setScale(scale)
			spriteArray[#spriteArray + 1] = sprite
			self:addChild(sprite)
		else
			error("not define")
		end
	end

	return spriteArray
end

function RichLabel:formatString(parseArray)
	for i,dic in ipairs(parseArray) do
		local text = dic.text
		if text then
			local textArr = self:stringToChar(text)
			dic.textArray = textArr
		end
	end
end

--文字解析，按照顺序转换成数组，每个数组对应特定的标签
function RichLabel:parseString(str)
	local clumpheadTab = {} -- 标签头
	--作用，取出所有格式为[xxxx]的标签头
	for w in string.gfind(str, "%b[]") do 
		if  string.sub(w,2,2) ~= "/" then-- 去尾
			table.insert(clumpheadTab, w)
		end
	end

	-- 解析标签
	local totalTab = {}
	for k,ns in pairs(clumpheadTab) do
		local tab = {}
		local tStr  
		-- 第一个等号前为块标签名
		string.gsub(ns, string.sub(ns, 2, #ns-1), function (w)
			local n = string.find(w, "=")
			if n then
				local temTab = self:stringSplit(w, " ") -- 支持标签内嵌
				for k,pstr in pairs(temTab) do
					local temtab1 = self:stringSplit(pstr, "=")
					
					local pname = temtab1[1]

					if k == 1 then 
						tStr = pname 
					end -- 标签头
					
					local js = temtab1[2]

					local p = string.find(js, "[^%d.]")

        			if not p then 
        				js = tonumber(js) 
        			end

					local switchState = {
						["fontColor"]	 = function()
							tab["fontColor"] = self:convertColor(js)
						end,
					} --switch end

					local fSwitch = switchState[pname] --switch 方法

					--存在switch
					if fSwitch then 
						--目前只是颜色需要转换
						local result = fSwitch() --执行function
					else --没有枚举
						tab[pname] = js		
						return
					end
				end
			end
		end)
		if tStr then
			-- 取出文本
			local beginFind,endFind = string.find(str, "%[%/"..tStr.."%]")
			local endNumber = beginFind-1
			local gs = string.sub(str, #ns+1, endNumber)
			if string.find(gs, "%[") then
				tab["text"] = gs
			else
				string.gsub(str, gs, function (w)
					tab["text"] = w
				end)
			end
			-- 截掉已经解析的字符
			str = string.sub(str, endFind+1, #str)
			table.insert(totalTab, tab)
		end
	end
	-- 普通格式label显示
	if table.nums(clumpheadTab) == 0 then
		local ptab = {}
		ptab.text = str
		table.insert(totalTab, ptab)
	end
	return totalTab
end


--[[解析16进制颜色rgb值]]
function  RichLabel:convertColor(xStr)
    local function toTen(v)
        return tonumber("0x" .. v)
    end

    local b = string.sub(xStr, -2, -1) 
    local g = string.sub(xStr, -4, -3) 
    local r = string.sub(xStr, -6, -5)

    local red = toTen(r) or self._fontColor.r
    local green = toTen(g) or self._fontColor.g
    local blue = toTen(b) or self._fontColor.b
    return ccc3(red, green, blue)
end

-- string.split()
function RichLabel:stringSplit(str, flag)
	local tab = {}
	while true do
		local n = string.find(str, flag)
		if n then
			local first = string.sub(str, 1, n-1) 
			str = string.sub(str, n+1, #str) 
			table.insert(tab, first)
		else
			table.insert(tab, str)
			break
		end
	end
	return tab
end

-- 拆分出单个字符
function RichLabel:stringToChar(str)
    local list = {}
    local len = string.len(str)
    local i = 1 
    while i <= len do
        local c = string.byte(str, i)
        local shift = 1
        if c > 0 and c <= 127 then
            shift = 1
        elseif (c >= 192 and c <= 223) then
            shift = 2
        elseif (c >= 224 and c <= 239) then
            shift = 3
        elseif (c >= 240 and c <= 247) then
            shift = 4
        end
        local char = string.sub(str, i, i+shift-1)
        i = i + shift
        table.insert(list, char)
    end
	return list, len
end



return RichLabel
