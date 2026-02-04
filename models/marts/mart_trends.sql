-- models/marts/mart_genre_stats.sql
WITH games_unnested AS (
    SELECT 
        appid,
        genre_name, -- Renamed for clarity
        price,
        metacritic
    FROM {{ ref('stg_games') }},
    UNNEST(genres) as genre_name -- Unfolds the array into rows
)

SELECT 
    genre_name as genre,
    COUNT(DISTINCT appid) as total_games,
    ROUND(AVG(price), 2) as avg_price,
    ROUND(AVG(metacritic), 1) as avg_rating
FROM games_unnested
GROUP BY 1
HAVING total_games > 10 -- Lowered threshold since you currently have ~2k games
ORDER BY total_games DESC