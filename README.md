![WAIEI Coreロゴ](sample/img/core-logo.png "WAIEI Coreロゴ")

# WAIEI Core
WAIEI CoreはStepMania5のテーマ開発において、簡単に便利な機能を実装することができるスクリプトファイル一式です

まだ製作途中なのでどんどん仕様が変わると思います


# 例
## WAIEI Coreバージョン取得

- 入力

```
'Version '..YA_VER:Display()
```

- 結果

```
Version 0.1.20180401
```

## Group.iniの特定のパラメータを取得

- 入力

```
local group = YA_GROUP:Open('FIXED Project')
group:Parameter('URL')
```

- 結果

```
https://sm.waiei.net/fixed/
```

- 使用後は閉じる必要があります

```
group:Close()
```

## 楽曲カラーを取得
楽曲カラー、MeterType、オリジナルグループフォルダ名は専用の関数で取得できます

- BGAnimations/ScreenSelectMusic overlay

```
-- 一度だけ呼び出す
YA_GROUP:Scan()
```

- Graphics/MusicWheelItem Song NormalPart等

```
-- colorにはdiffuseで使用可能なColor型が返却される
local color = YA_GROUP:MenuColor(GAMESTATE:GetCurrentSong())
```

## ユーザーカスタムソートの設定
Preferredソート時の並び順を設定します

- BGAnimations/ScreenSelectMusic overlay

```
-- 一度だけ呼び出す
YA_GROUP:SortSongs('test')
SONGMAN:SetPreferredSongs('test')
```

- OtherフォルダにSongManager test.txtが生成されます

## StepMania3.9同様のスコア計算式にする

- BGAnimations/ScreenGameplay overlay

```
return Def.ActorFrame{
    YA_SCORE:Actor('Classic')
};
```

- Metrics.ini

```
[Gameplay]
UseInternalScoring=YA_SCORE:InternalScoring()
```

※あくまで内部的なスコア処理が変わるだけなので、表示は各自で設定する必要があります


# ライセンス
MITだけど、ちゃんと1.0としてリリースするまで待ってくれると嬉しいな

1.0リリース時にはサンプルテーマも同梱予定


# TODO
- [x] VER
    - [x] CoreVersion(int)
    - [x] CoreVersion(text)
    - [x] StepManiaVersion(int)
- [ ] FILE
    - [x] Open
    - [x] GetParameter
    - [ ] Save
- [x] GROUP
- [x] SCORE
    - [x] A
    - [x] SN2
    - [x] Classic
    - [x] Hybrid
- [x] GAME
    - [x] ChangeScrollSpeed
    - [x] ChangeReverse
- [ ] EXFOLDER
- [ ] DRILL
- [x] SHARE
    - [x] TwitterResult
