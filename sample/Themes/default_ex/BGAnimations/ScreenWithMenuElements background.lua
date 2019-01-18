if YA_VER:Version() < 5100 then
	-- 5.0系
	return Def.ActorFrame {
	  FOV=90;
	  InitCommand=cmd(Center);
		Def.Quad {
			InitCommand=cmd(scaletoclipped,SCREEN_WIDTH,SCREEN_HEIGHT);
			OnCommand=cmd(diffuse,color("#05CBFF");diffusebottomedge,color("#F0BA00"));
		};
		Def.ActorFrame {
			InitCommand=cmd(hide_if,hideFancyElements;);
			LoadActor("../../default/BGAnimations/ScreenWithMenuElements background/_checkerboard") .. {
				InitCommand=cmd(rotationy,0;rotationz,0;rotationx,-90/4*3.5;zoomto,SCREEN_WIDTH*2,SCREEN_HEIGHT*2;customtexturerect,0,0,SCREEN_WIDTH*4/256,SCREEN_HEIGHT*4/256);
				OnCommand=cmd(texcoordvelocity,0,0.25;diffuse,color("#ffd400");fadetop,1);
			};
		};
		LoadActor("../../default/BGAnimations/ScreenWithMenuElements background/_particleLoader") .. {
			InitCommand=cmd(x,-SCREEN_CENTER_X;y,-SCREEN_CENTER_Y;hide_if,hideFancyElements;);
		};		
	};
else
	-- 5.1系
	local base         = '../../default/'
	local graphics     = base .. 'Graphics/'
	local bganimations = base .. 'BGAnimations/ScreenWithMenuElements background/'
	if ThemePrefs.Get("FancyUIBG") then
		return Def.ActorFrame {
			
			--[[
			LoadActor(graphics .. "common bg base") .. {
				InitCommand=cmd(Center;zoomto,SCREEN_WIDTH,SCREEN_HEIGHT)
			},
			--]]
			Def.Quad {
				InitCommand=cmd(scaletoclipped,SCREEN_WIDTH,SCREEN_HEIGHT;Center);
				OnCommand=cmd(diffuse,color("#05CBFF");diffusebottomedge,color("#F0BA00"));
			},
			
			LoadActor(bganimations .. "_maze") .. {
				OnCommand=cmd(Center;diffuse,color("#f6784922");effectperiod,10;spin;effectmagnitude,0,0,2.2)
			},
			
			LoadActor(bganimations .. "_barcode") .. {
				InitCommand=cmd(zoomto,36,1024;blend,'BlendMode_Add';x,SCREEN_LEFT+6;y,SCREEN_CENTER_Y;diffusealpha,0.08);
				OnCommand=cmd(customtexturerect,0,0,1,1;texcoordvelocity,0,-0.1);
			};
			LoadActor(bganimations .. "_barcode") .. {
				InitCommand=cmd(zoomto,36,1024;blend,'BlendMode_Add';x,SCREEN_RIGHT-6;y,SCREEN_CENTER_Y;diffusealpha,0.08);
				OnCommand=cmd(customtexturerect,0,0,1,1;texcoordvelocity,0,0.1);
			};
			
			Def.ActorFrame {
				OnCommand=cmd(diffusealpha,0;decelerate,1.8;diffusealpha,1;);
				LoadActor(bganimations .. "_tunnel1") .. {
					InitCommand=cmd(x,SCREEN_LEFT+160;y,SCREEN_CENTER_Y;blend,'BlendMode_Add';rotationz,-20),
					OnCommand=cmd(zoom,1.75;diffusealpha,0.14;spin;effectmagnitude,0,0,16.5)
				};	
				LoadActor(bganimations .. "_tunnel1") .. {
					InitCommand=cmd(x,SCREEN_LEFT+160;y,SCREEN_CENTER_Y;blend,'BlendMode_Add';rotationz,-10),
					OnCommand=cmd(zoom,1.0;diffusealpha,0.12;spin;effectmagnitude,0,0,-11)
				};
				LoadActor(bganimations .. "_tunnel1") .. {
					InitCommand=cmd(x,SCREEN_LEFT+160;y,SCREEN_CENTER_Y;blend,'BlendMode_Add';rotationz,0),
					OnCommand=cmd(zoom,0.5;diffusealpha,0.10;spin;effectmagnitude,0,0,5.5)
				};		
				LoadActor(bganimations .. "_tunnel1") .. {
					InitCommand=cmd(x,SCREEN_LEFT+160;y,SCREEN_CENTER_Y;blend,'BlendMode_Add';rotationz,-10),
					OnCommand=cmd(zoom,0.2;diffusealpha,0.08;spin;effectmagnitude,0,0,-2.2)
				};
			};
		};
	else
		--[[
		return 	LoadActor(graphics .. "common bg base") .. {
			InitCommand=cmd(Center;zoomto,SCREEN_WIDTH,SCREEN_HEIGHT)
		}
		--]]
		return Def.Quad {
			InitCommand=cmd(scaletoclipped,SCREEN_WIDTH,SCREEN_HEIGHT;Center);
			OnCommand=cmd(diffuse,color("#05CBFF");diffusebottomedge,color("#F0BA00"));
		}
	end
end
