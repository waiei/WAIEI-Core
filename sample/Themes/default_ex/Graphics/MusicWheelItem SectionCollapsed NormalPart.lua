local normalPart = ''
local colorPart = ''
if Extended:Is50() then
	normalPart = '../../default/Graphics/MusicWheelItem SectionCollapsed NormalPart'
	colorPart  = '../../default/Graphics/MusicWheelItem SectionCollapsed ColorPart'
else
	normalPart = '../../_fallback/Graphics/_blank'
	colorPart  = '../../default/Graphics/MusicWheelItem SectionCollapsed NormalPart'
end
return Def.ActorFrame{
	LoadActor(normalPart);
	LoadActor(colorPart)..{
		SetCommand=function(self,params)
			self:diffuse(BoostColor(Color('Orange'), 1.2))
		end
	};
	-- タイトル
	LoadFont('Common Normal')..{
		SetCommand=function(self,params)
			local order = GAMESTATE:GetSortOrder() or ''
			local text = params.Text
			if text then
				-- カスタムソート時のみgroup.iniのNAMEをチェック
				if ToEnumShortString(order) == 'Preferred' then
					text = YA_GROUP:GroupName(text)
				end
				self:diffuse(BoostColor(Color('Orange'), 1.2))
				self:shadowlength(1)
				self:shadowcolor(Color('Black'))
				self:settext(text)
				if Extended:Is50() then
					self:horizalign(center)
					self:maxwidth(194)
					self:x(-38)
					self:y(-2)
				else
					self:horizalign(left)
					self:maxwidth(SCREEN_WIDTH*0.31);
					self:x(-200)
					self:y(-2)
				end
			end
		end
	};
}