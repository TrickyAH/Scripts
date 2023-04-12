local games = {
    [{12135645852}] = {"https://raw.githubusercontent.com/TrickyAH/Scripts/main/Anime%20Catching%20Simulator%20Exploit"},
    [{9031522337}] = {"https://raw.githubusercontent.com/TrickyAH/Scripts/main/Rpg%20Champions%20Exploit"},
    [{9474703390, 10202329527, 11420877323, 9799727321}] = {"https://raw.githubusercontent.com/TrickyAH/Scripts/main/project_mugetsu.lua", "https://raw.githubusercontent.com/TrickyAH/Scripts/main/11420877323.lua", "https://raw.githubusercontent.com/TrickyAH/Scripts/main/10202329527.lua", "https://raw.githubusercontent.com/TrickyAH/Scripts/main/9799727321.lua"},
    [{8651781069}] = {"https://raw.githubusercontent.com/TrickyAH/Scripts/main/Voxlblade.lua"},
}

for ids, urls in next, games do
    if table.find(ids, game.PlaceId) then
        for _, url in ipairs(urls) do
            loadstring(game:HttpGet(url))();
        end
        break
    end
end
