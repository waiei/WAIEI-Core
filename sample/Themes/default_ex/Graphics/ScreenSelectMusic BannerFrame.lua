local banner
local w	-- BannerWidth
local h	-- BannerHeight
local c	-- BannerCropSize
--local bW = Extended:Is50() and 256 or 290
local bW = 256
local bH = 80
local bannerRatio = bH / bW
local bannerFrame
if Extended:Is50() then
	bannerFrame = '../../default/Graphics/ScreenSelectMusic BannerFrame'
else
	bannerFrame = '../../_fallback/Graphics/_blank'
end;
return Def.ActorFrame{
	LoadActor(bannerFrame);
	Def.Quad{
		InitCommand = cmd(visible,false);
		ChangeBannerMessageCommand = cmd(visible,true;zoomto,256,80;diffuse,0,0,0,0.66);
	};
	Def.Banner{
		ChangeBannerMessageCommand = function(self, params)
			-- いったんキャッシュ画像をロード
			if params.Banner then
				self:visible(true)
				banner = params.Banner
				self:finishtweening()
				self:LoadFromCachedBanner(params.Banner)
				self:stoptweening();
				self:rate(0.5);
				self:position(0);
				-- 縦に長いバナーは切り抜く （横に長い場合は縮小）
				w = self:GetWidth()
				h = self:GetHeight()
				if h/w < bannerRatio then
					self:scaletofit(-bW/2, -bH/2, bW/2, bH/2)
				else
					c = (h*bW/w-bH) / (h*bW/w) /2
					self:scaletocover(-bW/2, -bH/2, bW/2, bH/2)
					self:croptop(c)
					self:cropbottom(c)
				end
				self:sleep(0.2)
				self:queuecommand('SetOriginalBanner')
			end
		end;
		SetOriginalBannerCommand = function(self)
			-- 通常画像をロード
			self:Load(banner)
			self:stoptweening();
			self:rate(0.5);
			self:position(0);
			if h/w < bannerRatio then
				self:scaletofit(-bW/2, -bH/2, bW/2, bH/2)
			else
				c = (h*bW/w-bH) / (h*bW/w) /2
				self:scaletocover(-bW/2, -bH/2, bW/2, bH/2)
				self:croptop(c)
				self:cropbottom(c)
			end
		end
	};
}