
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
end

function MainScene:onEnter()

end

function MainScene:onExit()
end

return MainScene
