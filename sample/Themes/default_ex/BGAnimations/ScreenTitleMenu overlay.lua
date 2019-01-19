local zoom = SCREEN_HEIGHT / 480
return Def.ActorFrame{
	LoadActor(THEME:GetPathG('core', 'logo'))..{
		InitCommand = function(self)
			self:x(SCREEN_RIGHT-60*zoom)
			self:y(SCREEN_HEIGHT-80*zoom)
			self:zoom(0.25*zoom)
		end;
	};
}