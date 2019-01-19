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
	LoadActor('../../default/BGAnimations/ScreenEvaluation overlay');
	Def.ActorFrame{
		InitCommand=cmd(x,SCREEN_CENTER_X;y,SCREEN_HEIGHT*(Extended:Is50() and 0.84 or 0.9));
		Def.Quad{
			InitCommand=function(self)
				self:zoomto(SCREEN_WIDTH*0.07,SCREEN_HEIGHT*0.04)
				self:diffuse(Color('Outline'))
			end
		};
		Def.Quad{
			InitCommand=function(self)
				self:zoomto(SCREEN_WIDTH*0.07-4,SCREEN_HEIGHT*0.04-4)
				self:glowshift()
				self:diffuse(0,0,0,0.5)
			end
		};
		LoadFont('Common Normal')..{
			Text = '&MENUUP; Share';
			InitCommand=function(self)
				self:diffuse(Color('White'))
				self:zoom(Extended:Is50() and 0.4 or 0.7);
			end
		};
	}
}