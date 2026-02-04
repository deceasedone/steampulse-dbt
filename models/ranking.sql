-- models/marts/ranking.sql
with current_data as (
    select * from {{ ref('stg_games') }}
)

select
    appid,
    name,
    primary_genre,
    price,
    metacritic,
    total_reviews,
    release_date,
    
    -- New Metric: "Legacy Score" 
    -- (How many reviews per day has this game earned over its lifetime?)
    -- High Score = Viral Hit or All-time Classic. Low Score = Dead game.
    round(
        safe_divide(total_reviews, date_diff(current_date(), release_date, DAY)), 
        2
    ) as reviews_per_day,

    -- Rank games within their specific genre
    rank() over (partition by primary_genre order by total_reviews desc) as genre_rank

from current_data
where release_date is not null
order by total_reviews desc