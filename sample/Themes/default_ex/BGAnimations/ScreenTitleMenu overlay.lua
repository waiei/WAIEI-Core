return Def.ActorFrame{
	LoadActor(THEME:GetPathG('core', 'logo'))..{
		InitCommand = function(self)
			self:x(SCREEN_RIGHT-60)
			self:y(SCREEN_HEIGHT-80)
			self:zoom(0.25)
		end;
	};
}