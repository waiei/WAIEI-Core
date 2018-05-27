return Def.ActorFrame{
	-- スコア計算式の設定
	YA_SCORE:Actor('classic');
	-- リアルタイムスクロール（ハイスピード・Reverse）変更
	YA_SCROLL:Actor();
	-- ハイスピードとスクロール方向の変更が行われたときに表示
	Def.Actor{
		ChangeSpeedMessageCommand = function(self, params)
			_SYS(ToEnumShortString(params.Player)..' Speed:'..params.Display)
		end;
		ChangeReverseMessageCommand = function(self, params)
			_SYS(ToEnumShortString(params.Player)..' Scroll:'..params.Display)
		end;
	};
}