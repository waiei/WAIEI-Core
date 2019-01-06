--local text = YA_SHARE:Url(PLAYER_1)
--local size = 120
return Def.ActorFrame{
	YA_SHARE:Actor();
	--[[
	LoadActor(THEME:GetPathG('object', 'qrcode'), text, size)..{
		InitCommand=function(self)
			self:x(SCREEN_RIGHT - size/2 -10)
			self:y(SCREEN_HEIGHT - size/2 -45)
		end;
	};
	--]]
}