
local RichLabel = class("RichLabel", function()
    local node = display.newNode()
    return node
end)	

RichLabel.__index      = RichLabel
RichLabel._fontName = nil
RichLabel._fontSize = nil
RichLabel._fontColor = nil
RichLabel._containLayer = nil --装载layer
RichLabel._spriteArray = nil --精灵数组
RichLabel._textStr = nil
RichLabel._maxWidth = nil
RichLabel._maxHeight = nil

--目前支持参数
--[[
	文字 
	fontName  : font name
	fontSize  : number
	fontColor : ccc3(r,g,b) 字符串用十六进制，通用设置用ccc3

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

	--如果text的格式指定字体则使用指定字体，否则使用默认字体
	--大小和颜色同理
	local fontName = params.fontName or "Arial" --默认字体
	local fontSize = params.fontSize or 30 --默认大小
	local fontColor = params.fontColor or ccc3(255, 255, 255)
	local dimensions = params.dimensions or CCSize(0, 0) --默认无限扩展

	self._dimensions = dimensions

	--装文字和图片精灵
	local containLayer = display.newLayer()
	self:addChild(containLayer)
	self._containLayer = containLayer

    self._fontName = fontName
    self._fontSize = fontSize
    self._fontColor = fontColor
   
    self:setLabelString(text)
end

--设置text
function RichLabel:setLabelString(text)
	if self._textStr == text then
		return --相同则忽略
	end

	if self._textStr then --删除之前的string
		self._spriteArray = nil
		self._containLayer:removeAllChildren()
	end

	self._textStr = text
	
	--转化好的数组
	local parseArray = self:parseString_(text)

	--将字符串拆分成一个个字符
	self:formatString_(parseArray)

	--创建精灵
	local spriteArray = self:createSprite_(parseArray)
	self._spriteArray = spriteArray

	self:adjustPosition_()
end

--设置大小
function RichLabel:setDimensions(dimensions)
	self._containLayer:setContentSize(dimensions)
	self._dimensions = dimensions

	self:adjustPosition_()
end

function RichLabel:getLabelSize()
	local width = self._maxWidth or 0
	local height = self._maxHeight or 0
	return CCSize(width, height)
end

function RichLabel:getSizeOfSprites_(spriteArray)
	local widthArr = {} --宽度数组
	local heightArr = {} --高度数组

	--精灵的大小
	for i, sprite in ipairs(spriteArray) do
		local contentSize = sprite:getContentSize()
		widthArr[i] = contentSize.width
		heightArr[i] = contentSize.height
	end
	return widthArr, heightArr

end

function RichLabel:getPointOfSprite_(widthArr, heightArr, dimensions)
	local totalWidth = dimensions.width
	local totalHight = dimensions.height

	local maxWidth = 0
	local maxHeight = 0

	local spriteNum = #widthArr

	--从左往右，从上往下拓展
	local curX = 0 --当前x坐标偏移
	
	local curIndexX = 1 --当前横轴index
	local curIndexY = 1 --当前纵轴index
	
	local pointArrX = {} --每个精灵的x坐标

	local rowIndexArr = {} --行数组，以行为index储存精灵组
	local indexArrY = {} --每个精灵的行index

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
			pointX = curX + halfWidth --精灵坐标x
			curX = pointX + halfWidth --精灵最右侧坐标
			curIndexX = curIndexX + 1
		end
		pointArrX[i] = pointX --保存每个精灵的x坐标

		indexArrY[i] = rowIndex --保存每个精灵的行

		local tmpIndexArr = rowIndexArr[rowIndex]

		if not tmpIndexArr then --没有就创建
			tmpIndexArr = {}
			rowIndexArr[rowIndex] = tmpIndexArr
		end
		tmpIndexArr[#tmpIndexArr + 1] = i --保存相同行对应的精灵

		if curX > maxWidth then
			maxWidth = curX
		end
	end

	local curY = 0
	local rowHeightArr = {} --每一行的y坐标

	--计算每一行的高度
	for i, rowInfo in ipairs(rowIndexArr) do
		local rowHeight = 0
		for j, index in ipairs(rowInfo) do --计算最高的精灵
			local height = heightArr[index]
			if height > rowHeight then
				rowHeight = height
			end
		end
		local pointY = curY + rowHeight * 0.5 --当前行所有精灵的y坐标（正数，未取反）
		rowHeightArr[#rowHeightArr + 1] = - pointY --从左往右，从上到下扩展，所以是负数
		curY = curY + rowHeight --当前行的边缘坐标（正数）

		if curY > maxHeight then
			maxHeight = curY
		end
	end

	self._maxWidth = maxWidth
	self._maxHeight = maxHeight

	local pointArrY = {}

	for i = 1, spriteNum do
		local indexY = indexArrY[i] --y坐标是先读取精灵的行，然后再找出该行对应的坐标
		local pointY = rowHeightArr[indexY]
		pointArrY[i] = pointY
	end

	return pointArrX, pointArrY
end

--调整位置
function RichLabel:adjustPosition_()

	local spriteArray = self._spriteArray

	if not spriteArray then --还没创建
		return
	end

	--获得每个精灵的宽度和高度
	local widthArr, heightArr = self:getSizeOfSprites_(spriteArray)

	--获得每个精灵的坐标
	local pointArrX, pointArrY = self:getPointOfSprite_(widthArr, heightArr, self._dimensions)

	for i, sprite in ipairs(spriteArray) do
		sprite:setPosition(pointArrX[i], pointArrY[i])
	end
end
  
function RichLabel:createSprite_(parseArray)
	local spriteArray = {}

	for i, dic in ipairs(parseArray) do
		local textArr = dic.textArray
		if #textArr > 0 then --创建文字
			local fontName = dic.fontName or self._fontName
			local fontSize = dic.fontSize or self._fontSize
			local fontColor = dic.fontColor or self._fontColor
			for j, word in ipairs(textArr) do
				local label = CCLabelTTF:create(word, fontName, fontSize)
				label:setColor(fontColor)
				spriteArray[#spriteArray + 1] = label
				self._containLayer:addChild(label)
			end
		elseif dic.image then
			local sprite = CCSprite:create(dic.image)
			local scale = dic.scale or 1
			sprite:setScale(scale)
			spriteArray[#spriteArray + 1] = sprite
			self._containLayer:addChild(sprite)
		else
			error("not define")
		end
	end

	return spriteArray
end

function RichLabel:formatString_(parseArray)
	for i,dic in ipairs(parseArray) do
		local text = dic.text
		if text then
			local textArr = self:stringToChar_(text)
			dic.textArray = textArr
		end
	end
end

--文字解析，按照顺序转换成数组，每个数组对应特定的标签
function RichLabel:parseString_(str)
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
				local temTab = self:stringSplit_(w, " ") -- 支持标签内嵌
				for k,pstr in pairs(temTab) do
					local temtab1 = self:stringSplit_(pstr, "=")
					
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
							tab["fontColor"] = self:convertColor_(js)
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
function  RichLabel:convertColor_(xStr)
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
function RichLabel:stringSplit_(str, flag)
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
function RichLabel:stringToChar_(str)
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
