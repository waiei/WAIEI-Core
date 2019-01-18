YA_GROUP:SortSongs('test')
SONGMAN:SetPreferredSongs('test')
YA_GROUP:Scan()

if YA_VER:Version() < 5100 then
	return Def.ActorFrame{}
else
	return Def.ActorFrame{
		InitCommand=cmd(x,SCREEN_CENTER_X-227;y,SCREEN_TOP+175;draworder,-95;zoom,1.6);
		OffCommand=cmd(smooth,0.2;diffusealpha,0;);
		Def.Quad{
			InitCommand=cmd(zoomto,292,82;diffuse,0,0,0,1.0)
		};
		LoadActor(THEME:GetPathG('ScreenSelectMusic', 'BannerFrame'));
	}
end