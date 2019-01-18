return Def.ActorFrame {
	LoadActor('logo');
	LoadFont('Common Normal')..{
		Text = 'Powered by';
		InitCommand = function(self)
			self:diffuse(Color('White'))
			self:strokecolor(Color('Outline'))
			self:horizalign(center)
			self:zoom(2)
			self:addy(-100)
		end;
	};
	LoadFont('Common Normal')..{
		InitCommand = function(self)
			self:diffuse(Color('White'))
			self:strokecolor(Color('Outline'))
			self:horizalign(center)
			self:zoom(2)
			self:addy(100)
			self:settext('v'..YA_VER:Display())
		end;
	};
}