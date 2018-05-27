return Def.ActorFrame{
	LoadActor('../../default/Graphics/MusicWheelItem Song NormalPart');
	LoadActor('../../default/Graphics/MusicWheelItem Song ColorPart')..{
		SetCommand=function(self,params)
			local song = params.Song
			if song then
				self:diffuse(YA_GROUP:MenuColor(song))
			end
		end
	};
	-- タイトル
	LoadFont('Common Normal')..{
		SetCommand=function(self,params)
			local song = params.Song
			if song then
				local textZoom = (song:GetDisplaySubTitle() == '') and 1.0 or 0.75;
				self:diffuse(YA_GROUP:MenuColor(song))
				self:shadowlength(1)
				self:shadowcolor(Color('Black'))
				self:settext(song:GetDisplayMainTitle())
				self:horizalign(left)
				self:vertalign(top)
				self:zoom(textZoom)
				self:maxwidth(228/textZoom)
				self:x(-120)
				self:y(-17)
			end
		end
	};
	-- サブタイトル
	LoadFont('Common Normal')..{
		SetCommand=function(self,params)
			local song = params.Song
			if song then
				self:diffuse(YA_GROUP:MenuColor(song))
				self:shadowlength(1)
				self:shadowcolor(Color('Black'))
				self:settext(song:GetDisplaySubTitle())
				self:horizalign(left)
				self:zoom(0.5)
				self:maxwidth(228/0.5)
				self:x(-120)
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
				self:shadowlength(1)
				self:shadowcolor(Color('Black'))
				self:settext(song:GetDisplayArtist())
				self:horizalign(left)
				self:vertalign(bottom)
				self:zoom(textZoom)
				self:maxwidth(228/textZoom)
				self:x(-120)
				self:y(15)
				self:skewx(-0.2)
			end
		end
	};
}