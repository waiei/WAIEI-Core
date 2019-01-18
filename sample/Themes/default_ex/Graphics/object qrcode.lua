local str, size = ...;
local qrcode = YA_LIB.QR

size = size or 100;
local t=Def.ActorFrame{};
--local s = 5;
if qrcode then
	local ok, tab_or_message = qrcode.qrcode(str);
	if not ok then
		_SYS(tab_or_message);
	else
		local s = 1.0 * size / (#tab_or_message+8);
		t[#t+1]=Def.Quad{
			InitCommand=function(self)
				self:diffuse(Color('White'));
				self:zoomto(s*#tab_or_message+s*8,s*#tab_or_message+s*8);
			end;
		}
		for row=1,#tab_or_message do
			for col=1,#tab_or_message[row] do
				t[#t+1]=Def.Quad{
					InitCommand=function(self)
						local x = ((row-0.5)-(#tab_or_message/2))*s;
						local y = ((col-0.5)-(#tab_or_message/2))*s;
						self:x(x);
						self:y(y);
						self:diffuse(Color('Black'));
						self:visible(tab_or_message[col][row]>=0);
						self:zoomto(s,s);
					end;
				};
			end;
		end;
	end
end;

return t;
