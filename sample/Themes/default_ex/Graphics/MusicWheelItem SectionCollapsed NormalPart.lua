return Def.ActorFrame{
	LoadActor('../../default/Graphics/MusicWheelItem SectionCollapsed NormalPart');
	LoadActor('../../default/Graphics/MusicWheelItem SectionCollapsed ColorPart')..{
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
				self:maxwidth(194)
				self:x(-38)
				self:y(-2)
			end
		end
	};
}