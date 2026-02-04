WITH raw_source AS (
    SELECT * FROM {{ source('steam_raw', 'gcs_raw_json') }}
    WHERE string_field_0 IS NOT NULL
),

parsed_json AS (
    SELECT
        SAFE_CAST(json_value(string_field_0, '$.steam_id') AS INT64) as appid,
        json_value(string_field_0, '$.name') as name,
        
        -- NEW: Extract Publisher & Header Image
        json_value(string_field_0, '$.publishers[0]') as publisher,
        json_value(string_field_0, '$.header_image') as header_image,

        -- Extract ALL genres
        ARRAY(
            SELECT json_value(genre_element, '$.description')
            FROM UNNEST(JSON_QUERY_ARRAY(string_field_0, '$.genres')) AS genre_element
        ) AS genres,
        json_value(string_field_0, '$.genres[0].description') as primary_genre,

        -- Metrics
        COALESCE(SAFE_CAST(json_value(string_field_0, '$.price_overview.final') AS FLOAT64) / 100, 0) as price,
        json_value(string_field_0, '$.is_free') = 'true' as is_free,
        COALESCE(SAFE_CAST(json_value(string_field_0, '$.metacritic.score') AS INT64), 0) as metacritic,
        COALESCE(SAFE_CAST(json_value(string_field_0, '$.recommendations.total') AS INT64), 0) as total_reviews,
        
        -- DATE FIX: Try multiple formats for Steam dates (e.g. "8 Nov, 2024")
        COALESCE(
            SAFE.PARSE_DATE('%d %b, %Y', json_value(string_field_0, '$.release_date.date')), 
            SAFE.PARSE_DATE('%b %d, %Y', json_value(string_field_0, '$.release_date.date')),
            SAFE.PARSE_DATE('%Y-%m-%d', json_value(string_field_0, '$.release_date.date'))
        ) as release_date,

        CAST(json_value(string_field_0, '$.ingested_at') AS TIMESTAMP) as ingested_at
    FROM raw_source
)

SELECT * FROM parsed_json
QUALIFY ROW_NUMBER() OVER (PARTITION BY appid ORDER BY ingested_at DESC) = 1