--General SELECT
SELECT *
FROM stream
LIMIT 100

--Unique number of games in Stream table
SELECT count(distinct(game)) as No_of_games
from stream

--Unique Number of channels in Stream Table
SELECT count(distinct(channel)) as No_of_channels
from stream

--TOP 10 popular games
SELECT game, COUNT(*)
FROM stream
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

--Location of stream viewers who watches a game called 'League of Legends'
SELECT country, COUNT(*)
FROM stream
WHERE game = 'League of Legends'
GROUP BY 1
ORDER BY 2 DESC;

--Source the user is using to view the strem
SELECT player, COUNT(*)
FROM stream
GROUP BY 1
ORDER BY 2 DESC;

-- Adding a new column Genre: MOBA, FPS, Survival, Other
SELECT game,
 CASE WHEN game = 'Dota 2'
    THEN 'MOBA'
      WHEN game = 'League of Legends' 
    THEN 'MOBA'
      WHEN game = 'Heroes of the Storm'
    THEN 'MOBA'
      WHEN game = 'Counter-Strike: Global Offensive'
    THEN 'FPS'
      WHEN game = 'DayZ'
    THEN 'Survival'
      WHEN game = 'ARK: Survival Evolved'
    THEN 'Survival'
  ELSE 'Other'
  END AS 'genre',
  COUNT(*)
FROM stream
GROUP BY 1
ORDER BY 3 DESC;

--Joining two tables 
SELECT *
FROM stream
JOIN chat
  ON stream.device_id = chat.device_id;
