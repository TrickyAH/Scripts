local games = {
    [{12135645852}] = {"https://raw.githubusercontent.com/TrickyAH/Scripts/main/Anime%20Catching%20Simulator%20Exploit"},
    [{9031522337}] = {"https://raw.githubusercontent.com/TrickyAH/Scripts/main/Rpg%20Champions%20Exploit"},
    [{9474703390, 10202329527, 13117265227, 9799727321}] = {"https://raw.githubusercontent.com/TrickyAH/Scripts/main/project_mugetsu.lua", "https://raw.githubusercontent.com/TrickyAH/Scripts/main/9799727321.lua"},
    [{8651781069}] = {"https://raw.githubusercontent.com/TrickyAH/Scripts/main/Voxlblade.lua"},
    [{4505214429}] = {"https://raw.githubusercontent.com/TrickyAH/Scripts/main/Soul-Eater-Resonance.lua"},
    [{11542692507}] = "https://raw.githubusercontent.com/TrickyAH/Scripts/main/anime_souls_simulator.lua"},
}

for ids, urls in next, games do
    if table.find(ids, game.PlaceId) then
        for _, url in ipairs(urls) do
            loadstring(game:HttpGet(url))();
        end
        break
    end
end
