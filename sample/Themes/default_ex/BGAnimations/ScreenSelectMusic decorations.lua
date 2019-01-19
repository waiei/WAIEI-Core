local actors = Def.ActorFrame{};
if not Extended:Is50() then
	actors[#actors+1] = Def.ActorFrame{
		InitCommand=cmd(x,SCREEN_CENTER_X-227;y,SCREEN_TOP+175;draworder,-95;zoom,1.6);
		OffCommand=cmd(smooth,0.2;diffusealpha,0;);
		Def.Quad{
			InitCommand=cmd(zoomto,292,82;diffuse,0,0,0,0.75)
		};
		LoadActor(THEME:GetPathG('ScreenSelectMusic', 'BannerFrame'));
	};
end

actors[#actors+1] = LoadActor('../../default/BGAnimations/ScreenSelectMusic decorations');
return actors
