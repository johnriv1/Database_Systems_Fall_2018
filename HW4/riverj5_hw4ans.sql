SELECT 'Student: John Rivera (riverj5@rpi.edu)';

SELECT 'Query 1';

-- Return the full name of all contestants who had at least 5 consecutive wins (hint: check
-- out the description of contestants). Order by fullname.

-- Relations: contestants

SELECT
	c.fullname
FROM
	contestants c
WHERE
	c.description like '%whose 5-day cash winnings total%'
ORDER BY
	fullname;
	
	
	
SELECT 'Query 2';

-- Return the full name of all contestants whose short name start with letter ’b’ who answered
-- a daily double clue correctly (isdd is True) in the Double Jeopardy part of the short
-- (cat type is ’DJ’). Order by full name.

-- Relations: contestants (for fullname and shortname), clues (for isdd and cat_type='DJ'), 

SELECT DISTINCT
	c.fullname
	, c.shortname
FROM
	contestants c
	, clues cl
	, responses r
WHERE
	c.gameid = cl.gameid
	and r.gameid = c.gameid
	and r.shortname = c.shortname
	and r.clueid = cl.clueid
	and c.shortname like 'B%'
	and cl.isdd = TRUE
	and cl.cat_type = 'DJ'
	and r.iscorrect = TRUE
ORDER BY
	c.fullname ASC;


	
SELECT 'Query 3';

-- Return the gameid, clue text and category for all final jeopardy clues that were triple
-- stumpers (no contestant has answered them correctly). Order by gameid, clue, category.

-- Relations: final_clues(gameid, clue, category), final_response(iscorrect, shortname?)

-- first get final jeopardy clues that were guessed correctly eventually.
-- Then all final jeopardy clues - final jeopardy clues guessed correclty

SELECT
	fc.gameid
	, fc.clue
	, fc.category
FROM
	final_clues fc
	, final_responses fr
WHERE
	fc.gameid = fr.gameid
EXCEPT
SELECT
	fc.gameid
	, fc.clue
	, fc.category
FROM
	final_clues fc
	, final_responses fr
WHERE
	fc.gameid = fr.gameid
	and fr.iscorrect = TRUE
ORDER BY
	gameid, clue, category ASC;
	
-- or
/*
SELECT DISTINCT
	cl.gameid
	, cl.clue
        , cl.category
FROM
	final_clues cl
	, final_responses r
WHERE
    cl.gameid = r.gameid
	and (cl.gameid, cl.clue, cl.category) not in (SELECT 
														cl0.gameid
														, cl0.clue
														, cl0.category
													FROM 
														final_clues cl0
														, final_responses r0
													WHERE
														cl0.gameid = r0.gameid
														and r0.iscorrect = TRUE)
ORDER BY
	gameid, clue, category ASC;
*/
	
	
SELECT 'Query 4';

-- Return the id of all games, shortname for a pair of contestants in which at least two
-- contestants were tied going into final jeopardy (i.e. according to their scores in Round 3).
-- For each pair of contestants, only return one pair (alphabetically ordered). Order by gameid
-- and names.

-- Relations: scores(round = 3, score1 = score2, gameid, shortname)

SELECT
	s1.gameid
	, s1.shortname
	, s2.shortname
FROM
	scores s1
	, scores s2
WHERE
	s1.gameid = s2.gameid
	and s1.round = s2.round
	and s1.round = '3'
	and s1.shortname <> s2.shortname
	and s1.score = s2.score
	and s1.shortname < s2.shortname
ORDER BY
	s1.gameid
	, s1.shortname
	, s2.shortname;
	
SELECT 'Query 5';

-- Return all game rounds in which all clue categories were 11 characters or less (each
-- cat type value J or DJ is a different game round). Order by game id and category type.

SELECT
	gameid
	, cat_type
FROM
	clues
EXCEPT
SELECT
	gameid
	, cat_type
FROM
	clues
WHERE
	category like '%____________%'
ORDER BY
	gameid
	, cat_type;

	
	
SELECT 'Query 6';

-- Return the full name, final game score and description of contestants from ’Wisconsin’
-- with the highest final score in a single game. Order by full name and score.

-- Relations: contestants(fullname, description), scores(score, round = 'Final Score')

SELECT
	c1.fullname
	, s1.score
	, c1.description
FROM
	contestants c1
	, scores s1
WHERE
	s1.gameid = c1.gameid
	and s1.shortname = c1.shortname
	and c1.description like '%Wisconsin%'
	and s1.round = 'Final Score'
	and s1.score = (SELECT 
						max(s2.score) 
					FROM 
						scores s2
						, contestants c2
					WHERE 
						s2.gameid = c2.gameid
						and s2.shortname = c2.shortname
						and s2.round = 'Final Score' 
						and c2.description like '%Wisconsin%')
ORDER BY
	c1.fullname
	, s1.score;
	
-- gets max score in final round by someone in Wisconsin
/*SELECT 
	max(s.score) 
FROM 
	scores s
	, contestants c
WHERE 
	s.gameid = c.gameid
	and s.shortname = c.shortname
	and s.round = 'Final Score' 
	and c.description like '%Wisconsin%';
*/



SELECT 'Query 7';

-- For each contestant who competed in a game that aired in January, return the game
-- id, contestant full name and the total number of questions the contestant answered correctly
-- in the ’Double Jeopardy’ round of that game (considering only the games that the database
-- contains some clues for the ’Double Jeopardy’ round). Order by number of correct answers,
-- game id and full name.

-- Relations: contestant (gameid, fullname), games (airdate = January) 
--            clues (cat_type = 'DJ'), responses(iscorrect)

SELECT DISTINCT
	c.gameid
	, c.fullname
    , count(r.iscorrect) as numcorrect

FROM
	contestants c join games g on (c.gameid = g.gameid)
	join clues cl on (cl.gameid = g.gameid)
	left join responses r on (r.gameid = c.gameid
								and r.shortname = c.shortname
								and r.gameid = cl.gameid
								and r.clueid = cl.clueid
                                and r.iscorrect = TRUE)
WHERE
    cl.cat_type = 'DJ'
	and (g.airdate>='2018-01-01' and g.airdate<='2018-01-31')
GROUP BY
	c.gameid
	, c.fullname
ORDER BY
	numcorrect
	, gameid
	, fullname;

/*
-- Gets right answer, but bad
SELECT DISTINCT
	c0.gameid
	, c0.fullname
	, (SELECT 
			count(*)
		FROM
			contestants c1
			, responses r1
			, clues cl1
		WHERE 
			c1.gameid = c0.gameid
			and c1.shortname = c0.shortname
			and r1.gameid = c1.gameid
			and r1.shortname = c1.shortname
			and r1.gameid = cl1.gameid
			and r1.clueid = cl1.clueid
			and cl1.cat_type = 'DJ'
			and r1.iscorrect = TRUE) as numcorrect
FROM
	contestants c0
	, games g0
	, clues cl0
WHERE
	c0.gameid = g0.gameid
    and cl0.gameid = g0.gameid
    and cl0.cat_type = 'DJ'
	and (g0.airdate>='2018-01-01' and g0.airdate<='2018-01-31')
ORDER BY
	numcorrect
	, gameid
	, fullname;

-- contestants in a January game in which the game has a DJ round
SELECT DISTINCT
	c0.gameid
	, c0.fullname
        , g0.airdate 

FROM
	contestants c0
	, games g0
	, clues cl0
WHERE
	c0.gameid = g0.gameid
        and cl0.gameid = g0.gameid
        and cl0.cat_type = 'DJ'
	and (g0.airdate>='2018-01-01' and g0.airdate<='2018-01-31')
ORDER BY
	gameid
	, fullname;
*/

SELECT 'Query 8';

-- Find all contestants who have a game in which their Coryat score would have been at least ten
-- times as much as their Final score, even though their final score was more than 1000 (i.e. they
-- are really bad at betting). Return the gameid, shortname, their final score and the Coryat
-- score. Order by gameid and shortname.

-- Relations: scores(score at end of 'Coryat Score' round and 'Final Score' round, gameid, shortname)

SELECT
	s1.gameid, s1.shortname, s1.score as finalscore, s2.score as coryatscore
FROM
	scores s1
	, scores s2
WHERE
	s1.gameid = s2.gameid
	and s1.shortname = s2.shortname
	and s1.round = 'Final Score'
	and s1.score > 1000
	and s2.round = 'Coryat Score'
	and s2.score >= 10*s1.score
ORDER BY
	s1.gameid, s1.shortname;

	
	
SELECT 'Query 9';

-- Return the text of all clues that are about the ’Internet’ (either clue text or the category).
-- Order by clue text

-- Relations: clues(category = 'Internet' clue like '%internet%' or clue like '%Internet%')

SELECT
	cl.clue
FROM
	clues cl
WHERE
	cl.category like '%INTERNET%'
	or cl.clue like '%nternet%'
UNION
SELECT
	fcl.clue
FROM
	final_clues fcl
WHERE
	fcl.category like '%INTERNET%'
	or fcl.clue like '%nternet%'
ORDER BY
	clue;

	
	
SELECT 'Query 10';

-- Return the gameid, contestant short name and final score of all games in which the
-- contestant had a negative score in Round 2, but eventually won the game (with the highest
-- final score). Order by final score and game id.

-- Relations: scores

SELECT
	sfr.gameid
	, sfr.shortname
	, sr2.score as round2score
	, sfr.score as finalscore
FROM
	scores sr2
	, scores sfr
WHERE
	sr2.gameid = sfr.gameid
	and sr2.shortname = sfr.shortname
	and sr2.round = '2'
	and sr2.score < 0
	and sfr.round = 'Final Score'
	and sfr.score = (SELECT 
						max(sfr2.score)
					FROM 
						scores sfr2
					WHERE
						sfr2.round = 'Final Score'
						and sfr2.gameid = sfr.gameid
					GROUP BY
						sfr2.gameid)
ORDER BY
	sfr.score
	, sfr.gameid;

/*
-- all people (gameid, shortname) with negative scores but also won

SELECT
	s.gameid, s.shortname
FROM
	scores s
WHERE 
	s.round = '2'
	and s.score < 0;
INTERSECT
SELECT 
	s1.gameid
	, s1.shortname
FROM 
	scores s1
WHERE
	s1.round = 'Final Score'
	and s1.score = (SELECT 
						max(s2.score)
					FROM 
						scores s2
					WHERE
						s2.round = 'Final Score'
						and s2.gameid = s1.gameid
					GROUP BY
						s2.gameid);


-- all people with negative scores
SELECT
	s.gameid, s.shortname, s.score
FROM
	scores s
WHERE 
	s.round = '2'
	and s.score < 0;
	
-- All Winners
SELECT 
	s1.gameid
	, s1.shortname
FROM 
	scores s1
WHERE
	s1.round = 'Final Score'
	and s1.score = (SELECT 
						max(s2.score)
					FROM 
						scores s2
					WHERE
						s2.round = 'Final Score'
						and s2.gameid = s1.gameid
					GROUP BY
						s2.gameid);
					
-- gets max score per gameid
SELECT 
	s1.gameid
	, max(s1.score)
FROM 
	scores s1
WHERE
	s1.round = 'Final Score'
GROUP BY
	s1.gameid
ORDER BY
	s1.gameid;

*/