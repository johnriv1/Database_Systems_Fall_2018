SELECT 'Student: John Rivera (riverj5@rpi.edu)';

SELECT 'Query 1';

-- Return name of categories that appeared in final jeopardy 6 or more times and
-- never appeared in the other rounds of the game (i.e. in the clues table). Order by category
-- name.

SELECT
	fcl.category
FROM
	final_clues fcl
WHERE
	fcl.category not in (SELECT cl.category FROM clues cl)
GROUP BY
	fcl.category
HAVING
	count(*) >= 6
ORDER BY
	fcl.category;

	
	
SELECT 'Query 2';

-- Find the full name of the contestant with highest total score over all his/her games.
-- You can assume there is a single such person. (Note that the database does not contain the
-- championship rounds in case you are unsatisfied with the answer.)

-- Relations: scores(round = 'Final Score', score), contestants(fullname)

WITH totalscores as
	(SELECT
		c.fullname
		, sum(s.score) as score
	FROM
		scores s
		, contestants c
	WHERE
		s.gameid = c.gameid
		and s.shortname = c.shortname
		and s.round = 'Final Score'
	GROUP BY
		c.fullname)
SELECT
	*
FROM
	totalscores
WHERE
	totalscores.score = (SELECT 
							max(ts1.score) 
						 FROM
							totalscores ts1);

-- get max total score
/*
SELECT 
	max(totalscores.score)
FROM
	(SELECT
		sum(s.score) as score
	FROM
		scores s
		, contestants c
	WHERE
		s.gameid = c.gameid
		and s.shortname = c.shortname
		and s.round = 'Final Score'
	GROUP BY
		c.fullname) as totalscores
*/
-- Get fullname and associated total score for everyone
/*
SELECT
	c.fullname
	, sum(s.score)
FROM
	scores s
	, contestants c
WHERE
	s.gameid = c.gameid
	and s.shortname = c.shortname
	and s.round = 'Final Score'
GROUP BY
	c.fullname
*/



SELECT 'Query 3';

-- Find answers to clues that are longer than 20 characters that were answers
-- to more than 6 clues. Return the answer, the number of clues it was an answer to and the
-- number of categories that had a clue with this correct answer, order by the number of clues.

-- Relations: clues(clue longer than 20 characters)

SELECT
	cl.correct_answer
	, count(*) as numclue
	, count(DISTINCT category) as count
FROM
	clues cl
WHERE
	length(cl.correct_answer) > 20
GROUP BY
	cl.correct_answer
HAVING
	count(*)>6
ORDER BY
	numclue DESC;

	
	
SELECT 'Query 4';

-- Find categories that have a correct response less 60% of the time, order by the number
-- of different games these categories appeared in and return the top 20 most frequent such
-- categories.
--
-- For each category, return the name, number of games it appeared in, and the percentage of
-- correct answers in that category ( number of times a correct answer is given for a clue in this
-- category divided by the number of clues in the category).

SELECT
	cl.category
	, count(DISTINCT cl.gameid) as numtimes
	, cast((cast(count(r.iscorrect) as float)/cast(count(cl.clueid) as float)) as decimal(10,2)) as percentcorrect
FROM
	clues cl left join responses r on (r.gameid = cl.gameid
										and r.clueid = cl.clueid
										and r.iscorrect = TRUE)
GROUP BY
	cl.category
HAVING
	(cast(count(r.iscorrect) as float)/cast(count(cl.clueid) as float)) < 0.6
ORDER BY
	count(DISTINCT cl.gameid) DESC
LIMIT 20;



SELECT 'Query 5';

-- Find people who had higher scores than ’Ken Jennings’ (fullname) in Round
-- 3. Return their full name, gameid in which this happened and the score difference in Round
-- 3. Order by score difference.

-- Relations:

SELECT
    c2.fullname
	, s.gameid
	, (s2.score - s.score) as scorediff
FROM
	scores s
	, contestants c
    , scores s2
    , contestants c2
WHERE
	s.gameid = c.gameid
	and s.shortname = c.shortname
	and s2.gameid = c2.gameid
	and s2.shortname = c2.shortname
    and s.gameid = s2.gameid
	and s.round = '3'
    and s2.round = s.round
	and c.fullname = 'Ken Jennings'
	and s2.score > s.score
ORDER BY
	scorediff DESC;

-- Ken Jennings Round 3 Score Compared with Watson
/*
SELECT
	s.gameid
        , c.fullname, s.round, s.score
        , c2.fullname, s2.round, s2.score
FROM
	scores s
	, contestants c
        , scores s2
        , contestants c2
WHERE
	s.gameid = c.gameid
	and s.shortname = c.shortname
	and s2.gameid = c2.gameid
	and s2.shortname = c2.shortname
    and s.gameid = s2.gameid
	and s.round = '3'
    and s2.round = s.round
	and c.fullname = 'Ken Jennings'
	and c2.fullname = 'Watson';
*/
-- Ken Jennings Round 3 Score
/*
SELECT
	s.gameid, c.fullname, s.round, s.score
FROM
	scores s
	, contestants c
WHERE
	s.gameid = c.gameid
	and s.shortname = c.shortname
	and s.round = '3'
	and c.fullname = 'Ken Jennings';
*/



SELECT 'Query 6';

-- Return the gameid and air date of games that has at least 15 triple stumpers in Jeopardy
-- or Double Jeopardy rounds. Order their results by airdate.

-- Relations: games (airdate), clues (cat_type = 'J' or 'DJ'), responses(iscorrect)

SELECT DISTINCT
	g.gameid
	, g.airdate
FROM
	clues cl left join responses r on (cl.gameid = r.gameid
	                                   and cl.clueid = r.clueid)
	, games g
WHERE
	g.gameid = cl.gameid
	and (cl.cat_type = 'DJ' or cl.cat_type = 'J')
	and (cl.gameid, cl.clueid) not in (SELECT 
											r0.gameid
											, r0.clueid
										FROM 
											responses r0
										WHERE
											r0.iscorrect = TRUE)
GROUP BY
	g.gameid
	, g.airdate
HAVING
	count(cl.clueid) >= 15
ORDER BY
	g.airdate;

/* This is incorrect
SELECT DISTINCT
	g.gameid
	, g.airdate
FROM
	clues cl
	, responses r
	, games g
WHERE
	g.gameid = cl.gameid
	and cl.gameid = r.gameid
	and cl.clueid = r.clueid
	and (cl.cat_type = 'DJ' or cl.cat_type = 'J')
	and (cl.gameid, cl.clueid) not in (SELECT 
											r0.gameid
											, r0.clueid
										FROM 
											responses r0
										WHERE
											r0.iscorrect = TRUE)
GROUP BY
	g.gameid
	, g.airdate
HAVING
	count(cl.clueid) >= 15
ORDER BY
	g.airdate
*/
/* Correct triple stumper clues for gameid = 35
SELECT DISTINCT
	g.gameid
	, cl.clueid
        , r.iscorrect
        , cl.cat_type
FROM
	clues cl left join responses r on (cl.gameid = r.gameid
	                                   and cl.clueid = r.clueid)
	, games g
WHERE
	g.gameid = cl.gameid
	and (cl.cat_type = 'DJ' or cl.cat_type = 'J')
	and cl.gameid = 35
        and (cl.gameid, cl.clueid) not in (SELECT 
						r0.gameid
                                                , r0.clueid
					   FROM 
						responses r0
					   WHERE
						r0.iscorrect = TRUE)
*/



SELECT 'Query 7';

-- Find the full name and total winnings of the lowest total scoring 5 time champion (i.e.
-- sum of final scores of exactly 5 time champions in). (Note: This could be a pretty tricky
-- query. I recommend you use WITH here.)

-- Relations:

-- Get winners who won exactly 5 games (Group by winners, with games won as tuples)
-- the sum of final scores of each person, then get tuple associated with lowest sum
WITH max_score_per_game as
	(SELECT
		s1.gameid
		, max(s1.score) as max_score
	FROM
		scores s1
	WHERE
		s1.round = 'Final Score'
	GROUP BY
		s1.gameid)
SELECT
	c2.fullname, sum(s2.score) as winnings
FROM
	max_score_per_game
	, scores s2
	, contestants c2
WHERE
	max_score_per_game.gameid = s2.gameid
    and s2.shortname = c2.shortname
    and s2.gameid = c2.gameid
	and s2.round = 'Final Score'
	and s2.score = max_score_per_game.max_score
GROUP BY
	c2.fullname
HAVING
	count(*) = 5
ORDER BY
	winnings
LIMIT
	1;
	
-- get max score per game
/*
SELECT
	s1.gameid
	, max(s1.score)
FROM
	scores s1
WHERE
	s1.round = 'Final Score'
GROUP BY
	s1.gameid
*/



SELECT 'Query 8';

-- Find categories that appeared in two games more than 30 years between them (meaning
-- the category did not appear between two appearances that are 30 years apart.) Use 365 days
-- to represent a year.

-- Relations: games(airdate), clues(category)

SELECT DISTINCT
	cl10.category 
FROM
	clues cl10
	, games g10
	, clues cl20
	, games g20
WHERE
	cl10.gameid = g10.gameid
	and cl20.gameid = g20.gameid
	and cl10.category = cl20.category
	and g10.airdate > g20.airdate
	and (cl10.category, g10.airdate, g10.gameid) not in (SELECT DISTINCT
																cl1.category, g1.airdate, g1.gameid 
															FROM
																clues cl1
																, games g1
																, clues cl2
																, games g2
															WHERE
																cl1.gameid = g1.gameid
																and cl2.gameid = g2.gameid
																and cl1.category = cl2.category
																and g1.airdate > g2.airdate
																and (g1.airdate - g2.airdate) < 365*30);

/* Gets the category, airdate, game id tuples that had a pair that was less than 30 years apart
SELECT
	cl1.category, g1.airdate, g1.gameid 
FROM
	clues cl1
	, games g1
	, clues cl2
	, games g2
WHERE
	cl1.gameid = g1.gameid
	and cl2.gameid = g2.gameid
	and cl1.category = cl2.category
	and g1.airdate > g2.airdate
	and (g1.airdate - g2.airdate) < 365*30
*/



SELECT 'Query 9';

-- For each state, return the state name and the number of contestants per capita from
-- this state as well as the number of contestants (+1) who were at least 5 time champions per
-- capita (percapita5times) from this state. Order by percapita5times. Note: for this query,
-- we added a new table called states(name,population) To find a percapita value, you need to
-- divide the population of the state with number of contestants

-- Relations: states, contestants description = ...from...,...statename...

-- Both below combined
SELECT
	st.name
	, count(DISTINCT c1.fullname) as numcontestants
	, st.population/count(DISTINCT c1.fullname) as percapita
        , ceil(cast((st.population) as float)/(cast((1+count(DISTINCT c2.fullname)) as float))) as percapita5times

FROM
	states st join contestants c1 on (c1.description like '%from%,%' || cast((st.name) as varchar) || '%')
    left join contestants c2 on (c1.description = c2.description
                                    and c1.gameid = c2.gameid
                                    and c1.fullname = c2.fullname
                                    and c2.description like '%whose 5-day cash winnings total%')
GROUP BY
	st.name, st.population
ORDER BY
	percapita5times DESC;

-- All contestants in the state they live in
/*
SELECT
	st.name
	, count(DISTINCT fullname) as numcontestants
	, st.population/count(DISTINCT fullname) as percapita
FROM
	states st
	, contestants c1
WHERE
	c1.description like '%from%,%' || cast((st.name) as varchar) || '%'
GROUP BY
	st.name, st.population
*/
-- Only contestants who won at least 5 times in the state they live in
/*
SELECT
	st.name
	, count(DISTINCT fullname) as num_5plustimers
	, ceil(cast((st.population) as float)/(cast((1+count(DISTINCT fullname)) as float))) as percapita5times
FROM
	states st
	, contestants c1
WHERE
	c1.description like '%from%,%' || cast((st.name) as varchar) || '%'
	and c1.description like '%whose 5-day cash winnings total%'
GROUP BY
	st.name, st.population
ORDER BY
	percapita5times DESC
*/



SELECT 'Query 10';

-- FINAL JEOPARDY! Find the full name of contestants who won at least two games
-- in which they were third going into final jeopardy (i.e. at round 3). Order by name.

WITH max_score_per_game as
	(SELECT
		s1.gameid
		, max(s1.score) as max_score
	FROM
		scores s1
	WHERE
		s1.round = 'Final Score'
	GROUP BY
		s1.gameid)
SELECT
	c2.fullname
FROM
	max_score_per_game
	, scores s2
	, scores s3
	, contestants c2
WHERE
	max_score_per_game.gameid = s2.gameid
    and s2.shortname = c2.shortname
    and s2.gameid = c2.gameid
	
	and s3.shortname = c2.shortname
	and s3.gameid = c2.gameid
	
	and s2.round = 'Final Score'
	and s2.score = max_score_per_game.max_score
	
	and s3.round = '3'
	and (c2.gameid, c2.fullname, s3.score) in (	(SELECT
													s01.gameid
													, c01.fullname
													, s01.score
												FROM
													scores s01
													, scores s02
													, scores s03
													, contestants c01
												WHERE
													s01.gameid = c01.gameid
													and s01.shortname = c01.shortname
													and s01.round = '3'
													and s02.round = s01.round
													and s03.round = s01.round
													and s02.gameid = s01.gameid 
													and s03.gameid = s01.gameid 
													and s01.shortname <> s02.shortname 
													and s02.shortname <> s03.shortname
													and s01.shortname <> s03.shortname
													and s01.score < s02.score
													and s01.score < s03.score))
	
GROUP BY
	c2.fullname
HAVING
	count(*) >= 2;

/* Doesn't work
WITH max_score_per_game as
	(SELECT
		s1.gameid
		, max(s1.score) as max_score
	FROM
		scores s1
	WHERE
		s1.round = 'Final Score'
	GROUP BY
		s1.gameid),
	
	round_3_losers as 
	(SELECT
		s01.gameid
		, c01.fullname
		, s01.score
	FROM
		scores s01
		, scores s02
		, scores s03
		, contestants c01
	WHERE
		s01.gameid = c01.gameid
		and s01.shortname = c01.shortname
		and s01.round = '3'
		and s02.round = s01.round
		and s03.round = s01.round
		and s02.gameid = s01.gameid 
		and s03.gameid = s01.gameid 
		and s01.shortname <> s02.shortname 
		and s02.shortname <> s03.shortname
		and s01.shortname <> s03.shortname
		and s01.score < s02.score
		and s01.score < s03.score)
SELECT
	c2.fullname
FROM
	max_score_per_game
    , round_3_losers
	, scores s2
	, scores s3
	, contestants c2
WHERE
	max_score_per_game.gameid = s2.gameid
    and s2.shortname = c2.shortname
    and s2.gameid = c2.gameid
	
	and	round_3_losers.gameid = s3.gameid
	and s3.shortname = c2.shortname
	and s3.gameid = c2.gameid
	
	and s2.round = 'Final Score'
	and s2.score = max_score_per_game.max_score
	
	and s3.round = '3'
	and (c2.gameid, c2.fullname, s3.score) in round_3_losers
	
GROUP BY
	c2.fullname
HAVING
	count(*) >= 2;
*/

/*This version works but include round 3 least tie scores
WITH max_score_per_game as
	(SELECT
		s1.gameid
		, max(s1.score) as max_score
	FROM
		scores s1
	WHERE
		s1.round = 'Final Score'
	GROUP BY
		s1.gameid),
	
	least_score_in_round3_per_game as 
	(SELECT
		s0.gameid
		, min(s0.score) as least_score
	FROM
		scores s0
	WHERE
		s0.round = '3'
	GROUP BY
		s0.gameid)
SELECT
	c2.fullname
FROM
	max_score_per_game
    , least_score_in_round3_per_game
	, scores s2
	, scores s3
	, contestants c2
WHERE
	max_score_per_game.gameid = s2.gameid
    and s2.shortname = c2.shortname
    and s2.gameid = c2.gameid
	
	and	least_score_in_round3_per_game.gameid = s3.gameid
	and s3.shortname = c2.shortname
	and s3.gameid = c2.gameid
	
	and s2.round = 'Final Score'
	and s2.score = max_score_per_game.max_score
	
	and s3.round = '3'
	and s3.score = least_score_in_round3_per_game.least_score
	
GROUP BY
	c2.fullname
HAVING
	count(*) >= 2;
*/








