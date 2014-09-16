
local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()

	local RichLabel = require("app.scenes.RichLabel")
	local str = "[image=wsk1.png][/image]" --图片
	str = str.."[fontColor=f75d85 fontSize=20]hello world[/fontColor][fontColor=fefefe]这是测试代码[/fontColor]" --文字 颜色 大小
	str = str.."[fontColor=f75d85 fontName=ArialRoundedMTBold]看看效果如何[/fontColor]" --文字 颜色，字体
	str = str.."[fontColor=fefefe]!!!!![/fontColor]" --文字 颜色
	str = str.."[image=wsk1.png scale=1.3][/image]" --图片
	local params = {
						text = str,
						dimensions = CCSize(200, 200)
					}
	local testLabel = RichLabel:create(params)
	self:addChild(testLabel)

	testLabel:setPosition(display.cx, display.cy)

	self:performWithDelay(function () --大小测试
		testLabel:setDimensions(CCSize(300, 200))
		local size = testLabel:getLabelSize()
		print("CurSize:"..size.width.." "..size.height)
	end, 2)

	self:performWithDelay(function () --重新设置文字测试
		testLabel:setLabelString("[fontColor=f75d85 fontSize=20]hello world[/fontColor][fontColor=fefefe]这是测试代码[/fontColor]")
	
		local size = testLabel:getLabelSize()
		print("CurSize:"..size.width.." "..size.height)
	end, 3)
end

function MainScene:onEnter()

end

function MainScene:onExit()
end

return MainScene
