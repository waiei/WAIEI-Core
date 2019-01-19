local normalPart = ''
local colorPart = ''
local maxwidth = Extended:Is50() and 228 or SCREEN_WIDTH*0.24
if Extended:Is50() then
	normalPart = '../../default/Graphics/MusicWheelItem Song NormalPart'
	colorPart  = '../../default/Graphics/MusicWheelItem Song ColorPart'
else
	normalPart = '../../_fallback/Graphics/_blank'
	colorPart  = '../../default/Graphics/MusicWheelItem Song NormalPart'
end
return Def.ActorFrame{
	LoadActor(normalPart);
	LoadActor(colorPart)..{
		SetCommand=function(self,params)
			local song = params.Song
			if song then
				self:diffuse(YA_GROUP:MenuColor(song))
			end
		end
	};
	Def.ActorFrame{
		InitCommand=cmd(x,Extended:Is50() and 0 or -15; zoom,Extended:Is50() and 1.0 or 1.1);
		-- タイトル
		LoadFont('Common Normal')..{
			SetCommand=function(self,params)
				local song = params.Song
				if song then
					local textZoom = (song:GetDisplaySubTitle() == '') and 1.0 or 0.75;
					self:diffuse(YA_GROUP:MenuColor(song))
					self:settext(song:GetDisplayMainTitle())
					self:horizalign(left)
					self:vertalign(top)
					self:zoom(textZoom)
					self:maxwidth(maxwidth/textZoom)
					self:x(-120)
					self:y(-17)
					if Extended:Is50() then
						self:shadowlength(1)
						self:shadowcolor(Color('Black'))
					else
						self:addy(-5)
						self:strokecolor(Color('Outline'))
					end
				end
			end
		};
		-- サブタイトル
		LoadFont('Common Normal')..{
			SetCommand=function(self,params)
				local song = params.Song
				if song then
					self:diffuse(YA_GROUP:MenuColor(song))
					self:settext(song:GetDisplaySubTitle())
					self:horizalign(left)
					self:zoom(0.5)
					self:maxwidth(maxwidth/0.5)
					self:x(-120)
					if Extended:Is50() then
						self:shadowlength(1)
						self:shadowcolor(Color('Black'))
					else
						self:strokecolor(Color('Outline'))
					end
				end
			end
		};
		-- アーティスト
		LoadFont('Common Normal')..{
			SetCommand=function(self,params)
				local song = params.Song
				if song then
					local textZoom = (song:GetDisplaySubTitle() == '') and 0.66 or 0.6;
					self:diffuse(YA_GROUP:MenuColor(song))
					self:settext((Extended:Is50() and '' or '/')..song:GetDisplayArtist())
					self:horizalign(left)
					self:vertalign(bottom)
					self:zoom(textZoom)
					self:maxwidth(maxwidth/textZoom)
					self:x(-120)
					self:y(15)
					self:skewx(Extended:Is50() and -0.2 or -0.2)
					if Extended:Is50() then
						self:shadowlength(1)
						self:shadowcolor(Color('Black'))
					else
						self:addy(5)
						self:strokecolor(Color('Outline'))
					end
				end
			end
		};
	};
}