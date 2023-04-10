local games = {
    [{12135645852}] = "https://raw.githubusercontent.com/TrickyAH/Scripts/main/Anime%20Catching%20Simulator%20Exploit",
    [{9031522337}] = "https://raw.githubusercontent.com/TrickyAH/Scripts/main/Rpg%20Champions%20Exploit",
    [{9474703390, 10202329527, 11420877323}] = "https://raw.githubusercontent.com/TrickyAH/Scripts/main/project_mugetsu.lua", "https://raw.githubusercontent.com/TrickyAH/Scripts/main/11420877323.lua", "https://raw.githubusercontent.com/TrickyAH/Scripts/main/10202329527.lua"
}

for ids, url in next, games do
    if table.find(ids, game.PlaceId) then
        loadstring(game:HttpGet(url))(); break
    end
end
