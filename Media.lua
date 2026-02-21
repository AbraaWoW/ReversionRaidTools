local _, RRT = ... -- Internal namespace
RRT.LSM = LibStub("LibSharedMedia-3.0")
NSMedia = {}
--Sounds
RRT.LSM:Register("sound","|cFF4BAAC8Macro|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\macro.mp3]])
RRT.LSM:Register("sound","|cFF4BAAC801|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\1.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC802|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\2.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC803|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\3.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC804|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\4.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC805|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\5.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC806|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\6.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC807|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\7.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC808|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\8.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC809|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\9.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC810|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\10.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Dispel|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Dispel.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Yellow|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Yellow.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Orange|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Orange.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Purple|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Purple.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Green|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Green.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Moon|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Moon.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Blue|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Blue.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Red|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Red.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Skull|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Skull.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Gate|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Gate.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Soak|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Soak.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Fixate|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Fixate.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Next|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Next.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Interrupt|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Interrupt.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Spread|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Spread.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Break|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Break.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Targeted|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Targeted.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Rune|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Rune.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Light|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Light.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Void|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Void.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Debuff|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Debuff.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Clear|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Clear.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Stack|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Stack.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Charge|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Charge.ogg]])
RRT.LSM:Register("sound","|cFF4BAAC8Linked|r", [[Interface\Addons\ReversionRaidTools\Media\Sounds\Linked.ogg]])
--Fonts
RRT.LSM:Register("font","Expressway", [[Interface\Addons\ReversionRaidTools\Media\Fonts\Expressway.TTF]])
--StatusBars
RRT.LSM:Register("statusbar","Atrocity", [[Interface\Addons\ReversionRaidTools\Media\StatusBars\Atrocity]])

-- Memes for Break-Timer
NSMedia.BreakMemes = {
    {[[Interface\AddOns\ReversionRaidTools\Media\Memes\ZarugarPeace.blp]], 256, 256},
    {[[Interface\AddOns\ReversionRaidTools\Media\Memes\ZarugarChad.blp]], 256, 147},
    {[[Interface\AddOns\ReversionRaidTools\Media\Memes\Overtime.blp]], 256, 256},
    {[[Interface\AddOns\ReversionRaidTools\Media\Memes\TherzBayern.blp]], 256, 24},
    {[[Interface\AddOns\ReversionRaidTools\Media\Memes\senfisaur.blp]], 256, 256},
    {[[Interface\AddOns\ReversionRaidTools\Media\Memes\schinky.blp]], 256, 256},
    {[[Interface\AddOns\ReversionRaidTools\Media\Memes\TizaxHose.blp]], 202, 256},
    {[[Interface\AddOns\ReversionRaidTools\Media\Memes\ponkyBanane.blp]], 256, 174},
    {[[Interface\AddOns\ReversionRaidTools\Media\Memes\ponkyDespair.blp]], 256, 166},
    {[[Interface\AddOns\ReversionRaidTools\Media\Memes\docPog.blp]], 195, 211},
}

