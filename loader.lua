local games = {
    [{12135645852}] = "https://raw.githubusercontent.com/TrickyAH/Scripts/main/Anime%20Catching%20Simulator%20Exploit",
    [{9031522337}] = "https://raw.githubusercontent.com/TrickyAH/Scripts/main/Rpg%20Champions%20Exploit",
    [{9474703390, 10202329527}] = "https://raw.githubusercontent.com/TrickyAH/Scripts/main/project_mugetsu.lua",
}

for ids, url in next, games do
    if table.find(ids, game.PlaceId) then
        loadstring(game:HttpGet(url))(); break
    end
end
