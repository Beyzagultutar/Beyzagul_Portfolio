-- How many olympics games have been held?
SELECT COUNT(DISTINCT(games)) AS total_games
FROM olympics_history;

-- All Olympics games held so far.
SELECT DISTINCT year, season, city
FROM olympics_history
ORDER BY year;

-- The total no of nations who participated in each olympics game.
SELECT games, COUNT(DISTINCT(noc))
FROM olympics_history
GROUP BY games
ORDER BY games;

-- the nation has participated in all of the olympic games.
WITH total_games AS 
		(SELECT COUNT(DISTINCT(games)) AS total_number_of_games
	 		FROM olympics_history),
	 countries AS
		(SELECT olympics.games, noc.region AS country 
			 FROM olympics_history_noc_regions AS noc
			 INNER JOIN olympics_history AS olympics
			 ON noc.noc = olympics.noc
			 GROUP BY games, noc.region),
	 participated_countries AS
		 (SELECT country, COUNT(1) AS total_participated_games
		  	FROM countries
		 	GROUP BY country)
SELECT *
FROM participated_countries AS pc
INNER JOIN total_games AS tg
ON tg.total_number_of_games = pc.total_participated_games;

-- The sport which was played in all summer olympics.
WITH all_summer_sports AS
		(SELECT games, sport 
		FROM olympics_history
		WHERE games LIKE '%Summer'),
	 summer_olympics AS
	 	(SELECT COUNT(DISTINCT(games)) AS total_games_in_summer
		FROM olympics_history
		WHERE games LIKE '%Summer'),
	 number_of_summer_olympics AS
	 	(SELECT sport, COUNT(DISTINCT(games)) AS n_summer_sports
		 FROM all_summer_sports
		GROUP BY sport)
SELECT *
FROM number_of_summer_olympics nofsm
INNER JOIN summer_olympics so ON
so.total_games_in_summer=nofsm.n_summer_sports
ORDER BY n_summer_sports DESC;

-- The sports that were just played only once in the olympics
WITH ta AS
	(SELECT DISTINCT(games), sport
	 FROM olympics_history),
	 tb AS
	 (SELECT sport, COUNT(games) AS no_of_game
	 FROM ta
	 GROUP BY sport)
SELECT tb.*, ta.games
FROM tb
INNER JOIN ta ON ta.sport =  tb.sport
WHERE tb.no_of_game = 1
ORDER BY ta.sport;

-- The total no of sports played in each olympic games.
SELECT COUNT(DISTINCT sport) AS no_of_sports_played, games
FROM olympics_history
GROUP BY games
ORDER BY no_of_sports_played DESC;

-- The oldest athletes to win a gold medal.
WITH t1 AS
	(SELECT name, sex, age, team, games, city, sport, event, medal
	FROM olympics_history
	WHERE medal = 'Gold' AND age != 'NA'
	ORDER BY age ASC),
	t2 AS
	(SELECT *, RANK() OVER (ORDER BY age ASC)
		FROM t1)
SELECT *
FROM t2
WHERE rank=1;

-- The ratio of female and male athletes participated in all olympic games.
SELECT CAST(female_ratio AS float)/ CAST(male_ratio AS float) AS female_male_ratio
FROM	(SELECT 
			SUM(CASE sex 
				WHEN 'F' THEN 1
				ELSE 0 END) AS female_ratio,	
		 SUM(CASE sex 
				WHEN 'M' THEN 1
				ELSE 0 END) AS male_ratio	
		FROM olympics_history) AS ratio_f_m;
		
-- The top 5 athletes who have won the most gold medals.
WITH COUNT AS
	(SELECT name, COUNT(medal) AS total_gold_metals
	 	FROM olympics_history
		WHERE medal = 'Gold'
	 	GROUP BY name
		ORDER BY total_gold_metals DESC),
	 ranking AS
	(SELECT *, DENSE_RANK() OVER (ORDER BY total_gold_metals DESC) AS rank
	FROM count)
SELECT *
FROM ranking
WHERE rank <= 5;

-- The top 5 athletes who have won the most medals (gold/silver/bronze
With athletes_with_medals AS
	(SELECT name, COUNT(1) AS total_medals
	FROM olympics_history
	WHERE medal in ('Gold', 'Silver', 'Bronze')
	GROUP BY name
	ORDER BY total_medals DESC),
	ranking AS
	(SELECT *, DENSE_RANK() OVER (ORDER BY total_medals DESC) AS rank
	FROM athletes_with_medals)
SELECT name, total_medals, rank
FROM ranking
WHERE rank <= 5;

-- The top 5 countries that have won the most medals in the Olympics
WITH countries AS
		(SELECT noc.region AS country, COUNT(olympics.medal) AS total_medals
			 FROM olympics_history_noc_regions AS noc
			 INNER JOIN olympics_history AS olympics
			 ON noc.noc = olympics.noc
			 GROUP BY noc.region, olympics.medal),
	ranking AS 
		(SELECT country, total_medals, DENSE_RANK() OVER (ORDER BY total_medals DESC) AS rank
	FROM countries)
SELECT country, total_medals, rank
FROM ranking
WHERE rank <=5;

-- Total gold, silver and broze medals won by each country. PIVOT.
CREATE EXTENSION TABLEFUNC;
    SELECT country
    	, coalesce(gold, 0) as gold
    	, coalesce(silver, 0) as silver
    	, coalesce(bronze, 0) as bronze
    FROM CROSSTAB('SELECT nr.region as country
    			, medal
    			, count(1) as total_medals
    			FROM olympics_history oh
    			JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    			where medal <> ''NA''
    			GROUP BY nr.region,medal
    			order BY nr.region,medal',
            'values (''Bronze''), (''Gold''), (''Silver'')')
    AS FINAL_RESULT(country varchar, bronze bigint, gold bigint, silver bigint)
    order by gold desc, silver desc, bronze desc;

-- The sport with the most medals UK won
WITH total_medal AS
		(SELECT sport, COUNT(1) total_medal_by_UK
		FROM olympics_history
		WHERE noc ='GBR' and medal != 'NA'
		GROUP BY noc, sport
		ORDER BY total_medal_by_UK DESC),
		ranking AS
		(SELECT *, DENSE_RANK() OVER (ORDER BY total_medal_by_UK DESC) AS rank
		 FROM total_medal)
SELECT *
FROM ranking
WHERE rank = 1;

-- All olympic games where United Kingdom won medal for Swimming and total medals in each olympic games.
WITH medals_in_swimming AS
	(SELECT team, sport, games, medal
	FROM olympics_history
	WHERE noc ='GBR' and medal != 'NA' and sport = 'Swimming'),
	medals_in_games AS
	(SELECT team, sport, games, COUNT(medal) as total_medals
	FROM medals_in_swimming
	GROUP BY team, sport, games)
SELECT team, sport, games, total_medals
FROM medals_in_games
ORDER BY total_medals DESC
