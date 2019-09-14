SELECT 'Student: Sibel Adali (adalis@rpi.edu)';

create table scores2 as select * from scores ;
create table contestants2 as select * from contestants ;
alter table contestants2 add iswinner boolean ;  

SELECT 'Problem 1';

UPDATE 
	contestants2
SET
	iswinner = TRUE
WHERE
	(gameid, shortname) in 
		(SELECT 
			s1.gameid
			, s1.shortname
		FROM 
			scores s1
		WHERE
			s1.round = 'Final Score'
			and (s1.score = (SELECT 
								max(s2.score)
							FROM 
								scores s2
							WHERE
								s2.round = 'Final Score'
								and s2.gameid = s1.gameid
							GROUP BY
								s2.gameid)) or s1.score is NULL); 
UPDATE
	contestants2
SET
	iswinner = FALSE
WHERE
	(iswinner <> TRUE or iswinner is NULL);	

/* This also works and may be faster, but it looks messier
UPDATE 
	contestants2
SET
	iswinner = case
				when (gameid, shortname) in 
					(SELECT 
						s1.gameid
						, s1.shortname
					FROM 
						scores s1
					WHERE
						s1.round = 'Final Score'
						and (s1.score = (SELECT 
											max(s2.score)
										FROM 
											scores s2
										WHERE
											s2.round = 'Final Score'
											and s2.gameid = s1.gameid
										GROUP BY
											s2.gameid)) or s1.score is NULL) then TRUE
				else FALSE
			   end
*/	
	
-- Find winners: find contestants who do not have a final score 
--               and there is no other player with a higher final score
--               *Two players with same highest final score both count as winners
/*
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
*/

SELECT 'Problem 2';

-- Insert your solution to Problem 2 here
-- Your solution should only create a table
-- follows(gameid1, gameid2)
-- and populate it, and nothing else.

CREATE TABLE follows(
	gameid1 int
	, gameid2 int
    , PRIMARY KEY (gameid1, gameid2)
);

-- combine everything

INSERT INTO follows
	SELECT DISTINCT
		*
	FROM (
			(SELECT
				g1.gameid
				, g2.gameid
			FROM
				games g1
				, games g2
			WHERE
				g2.airdate = g1.airdate+1
				or (extract(isodow from g1.airdate) = 5 and g2.airdate = g1.airdate + 3))
		UNION
			(SELECT
				g1.gameid
				, g2.gameid
			FROM
				games g1
				, games g2
				, contestants c1
				, contestants c2
			WHERE
				c1.gameid = g1.gameid
				and c2.gameid = g2.gameid
				
				-- game less than 60 days apart
				and g2.airdate > g1.airdate
				and (g2.airdate - g1.airdate) < 60
				
				-- they share a contestant
				and c1.fullname = c2.fullname 
				
				--no game between them
				and NOT EXISTS
					(SELECT
						g_between.airdate
					FROM
						games g_between
					WHERE
						g_between.airdate < g2.airdate
						and g_between.airdate > g1.airdate))) as a;
/*
-- first insert games with consecutive dates
INSERT INTO follows
SELECT
	g1.gameid
	, g2.gameid
FROM
	games g1
	, games g2
WHERE
	g2.airdate = g1.airdate+1;

-- second insert dates where one date is a friday and the other one 
-- is the following monday
INSERT INTO follows
SELECT
	g1.gameid
	, g2.gameid
FROM
	games g1
	, games g2
WHERE
	extract(isodow from g1.airdate) = 5 and g2.airdate = g1.airdate + 3;

-- insert dates of games where there are no games/dates in between them, 
-- they share a contestant,
-- Only consider game less than 60 days apart
INSERT INTO follows
SELECT
	g1.gameid
	, g2.gameid
FROM
	games g1
	, games g2
	, contestants c1
	, contestants c2
WHERE
	c1.gameid = g1.gameid
	and c2.gameid = g2.gameid
	
	-- game less than 60 days apart
	and g2.airdate > g1.airdate
	and (g2.airdate - g1.airdate) < 60
	
	-- they share a contestant
	and c1.fullname = c2.fullname 
	
	--no game between them
	and NOT EXISTS
		(SELECT
			g_between.airdate
		FROM
			games g_between
		WHERE
			g_between.airdate < g2.airdate
			and g_between.airdate > g1.airdate);	
*/


SELECT 'Problem 3';

-- Insert the code for creating your trigger for Problem 3 here.
-- Your code should only create a trigger named
-- scores_trigger and a function named scores_trigger_f
-- and nothing else.

CREATE FUNCTION scores_trigger_f() RETURNS trigger AS $scores_trigger$
	BEGIN
		IF (NEW.round = 'Final Score') THEN
			UPDATE 
				contestants2
			SET
				iswinner = case
					when (gameid, shortname) in 
						(SELECT 
							s1.gameid
							, s1.shortname
						FROM 
							scores2 as s1
						WHERE
							s1.gameid = NEW.gameid
							and s1.round = 'Final Score'
							and (s1.score = (SELECT 
												max(s2.score)
											FROM 
												scores2 s2
											WHERE
												s2.round = 'Final Score'
												and s2.gameid = s1.gameid
											GROUP BY
												s2.gameid)) or s1.score is NULL) then TRUE
							else FALSE
						   end
			WHERE
				gameid = NEW.gameid;
		END IF;
		RETURN NEW;
	END;
$scores_trigger$ LANGUAGE plpgsql;

CREATE TRIGGER scores_trigger AFTER UPDATE on scores2
	FOR EACH ROW EXECUTE PROCEDURE scores_trigger_f();

SELECT 'Problem 4';

-- Insert the code for creating your function for Problem 4 here.
-- Your code should only create a single function named
-- parsingreport(input_year)
-- and nothing else

-- Function for
-- How many contestants have zero responses (to any regular and final clue) in the database
-- for a game they participated in
CREATE FUNCTION parsingreport(input_year int) RETURNS text AS $ans$
	declare
		ans text;
	BEGIN
		
		WITH t1 as 
			(SELECT count(*) as zeroresponse FROM (
				(SELECT
				   c1.fullname
				   , c1.gameid
				   , count(r1.gameid) as numresponse
				   , count(fr1.gameid) as numfinalresponse
				FROM
				   contestants c1 left join responses r1 on
					  (c1.gameid = r1.gameid
					   and c1.shortname = r1.shortname)

				   left join final_responses fr1 on
					  (c1.gameid = fr1.gameid
					   and c1.shortname = fr1.shortname)

				   , games g1

				WHERE
				   g1.gameid = c1.gameid
				   and extract(year from g1.airdate) = input_year

				GROUP BY
				   c1.fullname, c1.gameid
				HAVING
				   count(r1.gameid)=0
				   and count(fr1.gameid)=0)) as foo)
				   
		,  t2 as ((WITH game_and_total_clues as
				(SELECT
					cl_count.gameid, (61-(fcl_count.num + cl_count.num)) as clue_count_per_game, cl_count.airdate
				FROM
					(SELECT
						cl.gameid, count(*) as num, g.airdate
					FROM
						games g left join clues cl on
							(g.gameid = cl.gameid)
					GROUP BY
						cl.gameid, g.airdate) cl_count

					, (SELECT
						fcl.gameid, count(*) as num, g.airdate
					FROM
						games g left join final_clues fcl on
							(g.gameid = fcl.gameid)
					GROUP BY
						fcl.gameid, g.airdate) fcl_count
						
				WHERE
					cl_count.gameid = fcl_count.gameid)
					-- and extract(year from cl_count.airdate) = '2012')
					
			SELECT
				extract(year from gnc.airdate) as year, sum(gnc.clue_count_per_game) as total
			FROM
				game_and_total_clues gnc
			WHERE
				extract(year from gnc.airdate) = input_year
			GROUP BY
				extract(year from gnc.airdate))
			-- UNION USED TO MAKE SURE t2 RETURNS AT LEAST ONE ROW
            UNION
                (SELECT input_year as year, 0 as total))
				
		, t3 as
			(SELECT count(*) as missing_fr FROM (
				(SELECT
				   c1.fullname
				   , c1.gameid
				   , count(fr1.gameid) as numfinalresponse
				FROM
				   contestants c1 
				   left join final_responses fr1 on
					  (c1.gameid = fr1.gameid
					   and c1.shortname = fr1.shortname)
				   , games g1
				WHERE
				   g1.gameid = c1.gameid
					   and c1.gameid in
					(SELECT
						gameid
					FROM
						final_clues)
				   and (c1.gameid, c1.shortname) in
					(SELECT
						c2.gameid, c2.shortname
					FROM
						contestants c2
						, scores s2
					WHERE
						s2.gameid = c2.gameid
						and s2.shortname = c2.shortname
						and s2.round = '3'
						and s2.score > 0)
				   and extract(year from g1.airdate) = input_year

				GROUP BY
				   c1.fullname, c1.gameid
				HAVING
				   count(fr1.gameid)=0)) as foo2)
	
		(SELECT 'Year: '|| input_year || E'\n' || 
				t1.zeroresponse ||' contestants with no clues' || E'\n' || 
				(SELECT sum(t.total) FROM t2 t) || ' missing clues' || E'\n' ||
				t3.missing_fr || ' missing final responses' 
		FROM t1, t2, t3) into ans;
		RETURN ans;
	END;
$ans$ LANGUAGE plpgsql;

/* ANOTHER SOULTION

SELECT 'Problem 4';

CREATE FUNCTION parsingreport(input_year int) RETURNS text AS $$
	declare
		ans TEXT;
		zeroresponse TEXT;
		missing_fr TEXT;
		missing_cl TEXT;
	BEGIN
		
		ans = 'Year ' || input_year || E'\n';
		
		SELECT cast(count(*) as TEXT) into zeroresponse 
		FROM (
				(SELECT
				   c1.fullname
				   , c1.gameid
				   , count(r1.gameid) as numresponse
				   , count(fr1.gameid) as numfinalresponse
				FROM
				   contestants c1 left join responses r1 on
					  (c1.gameid = r1.gameid
					   and c1.shortname = r1.shortname)

				   left join final_responses fr1 on
					  (c1.gameid = fr1.gameid
					   and c1.shortname = fr1.shortname)

				   , games g1

				WHERE
				   g1.gameid = c1.gameid
				   and extract(year from g1.airdate) = input_year

				GROUP BY
				   c1.fullname, c1.gameid
				HAVING
				   count(r1.gameid)=0
				   and count(fr1.gameid)=0)) as foo;
				   
		ans = ans || zeroresponse || ' contestants with no clues' ||  E'\n';
				   
		WITH  t2 as ((WITH game_and_total_clues as
				(SELECT
					cl_count.gameid, (61-(fcl_count.num + cl_count.num)) as clue_count_per_game, cl_count.airdate
				FROM
					(SELECT
						cl.gameid, count(*) as num, g.airdate
					FROM
						games g left join clues cl on
							(g.gameid = cl.gameid)
					GROUP BY
						cl.gameid, g.airdate) cl_count

					, (SELECT
						fcl.gameid, count(*) as num, g.airdate
					FROM
						games g left join final_clues fcl on
							(g.gameid = fcl.gameid)
					GROUP BY
						fcl.gameid, g.airdate) fcl_count
						
				WHERE
					cl_count.gameid = fcl_count.gameid)
					-- and extract(year from cl_count.airdate) = '2012')
					
			SELECT
				extract(year from gnc.airdate) as year, sum(gnc.clue_count_per_game) as total
			FROM
				game_and_total_clues gnc
			WHERE
				extract(year from gnc.airdate) = input_year
			GROUP BY
				extract(year from gnc.airdate))
			-- UNION USED TO MAKE SURE t2 RETURNS AT LEAST ONE ROW
            UNION
                (SELECT input_year as year, 0 as total))
		
		SELECT cast(sum(t.total) AS TEXT) into missing_cl FROM t2 t;
		
		ans = ans || missing_cl || ' missing clues' || E'\n';
				
		SELECT cast(count(*) as TEXT) into missing_fr 
		FROM (
				(SELECT
				   c1.fullname
				   , c1.gameid
				   , count(fr1.gameid) as numfinalresponse
				FROM
				   contestants c1 
				   left join final_responses fr1 on
					  (c1.gameid = fr1.gameid
					   and c1.shortname = fr1.shortname)
				   , games g1
				WHERE
				   g1.gameid = c1.gameid
					   and c1.gameid in
					(SELECT
						gameid
					FROM
						final_clues)
				   and (c1.gameid, c1.shortname) in
					(SELECT
						c2.gameid, c2.shortname
					FROM
						contestants c2
						, scores s2
					WHERE
						s2.gameid = c2.gameid
						and s2.shortname = c2.shortname
						and s2.round = '3'
						and s2.score > 0)
				   and extract(year from g1.airdate) = input_year

				GROUP BY
				   c1.fullname, c1.gameid
				HAVING
				   count(fr1.gameid)=0)) as foo2;
	
		ans = ans || missing_fr || ' missing final responses';
		
		RETURN ans;
	END;
$$ LANGUAGE plpgsql;
*/

-- How many contestants have zero responses (to any regular and final clue) in the database
-- for a game they participated in. FOR 2012
/*
SELECT count(*) FROM (
	(SELECT
	   c1.fullname
	   , c1.gameid
	   , count(r1.gameid) as numresponse
	   , count(fr1.gameid) as numfinalresponse
	FROM
	   contestants c1 left join responses r1 on
		  (c1.gameid = r1.gameid
		   and c1.shortname = r1.shortname)

	   left join final_responses fr1 on
		  (c1.gameid = fr1.gameid
		   and c1.shortname = fr1.shortname)

	   , games g1

	WHERE
	   g1.gameid = c1.gameid
	   and extract(year from g1.airdate) = '2012'

	GROUP BY
	   c1.fullname, c1.gameid
	HAVING
	   count(r1.gameid)=0
	   and count(fr1.gameid)=0)) as foo;
*/
--SELECT t.missingresponse || 'missing final responses';

/*
SELECT
   c1.fullname
   , c1.gameid
   , count(r1.gameid) as numresponse
   , count(fr1.gameid) as numfinalresponse
FROM
   contestants c1 left join responses r1 on
      (c1.gameid = r1.gameid
       and c1.shortname = r1.shortname)

   left join final_responses fr1 on
      (c1.gameid = fr1.gameid
       and c1.shortname = fr1.shortname)

   , games g1

WHERE
   g1.gameid = c1.gameid
   and extract(year from g1.airdate) = '2012'

GROUP BY
   c1.fullname, c1.gameid
HAVING
   count(r1.gameid)=0
   and count(fr1.gameid)=0;
*/

-- How many total clues are missing (including regular and final clues).
-- Note that each game should have a total of 1+2x6x5= 61 clues. Use this to compute
-- how many clues there should be.
/*
WITH game_and_total_clues as
    (SELECT
		cl_count.gameid, (61-(fcl_count.num + cl_count.num)) as clue_count_per_game, cl_count.airdate
	FROM
		(SELECT
			cl.gameid, count(*) as num, g.airdate
		FROM
			games g left join clues cl on
				(g.gameid = cl.gameid)
		GROUP BY
			cl.gameid, g.airdate) cl_count

		, (SELECT
			fcl.gameid, count(*) as num, g.airdate
		FROM
			games g left join final_clues fcl on
				(g.gameid = fcl.gameid)
		GROUP BY
			fcl.gameid, g.airdate) fcl_count
			
	WHERE
		cl_count.gameid = fcl_count.gameid)
		-- and extract(year from cl_count.airdate) = '2012')
		
SELECT
	extract(year from gnc.airdate), sum(gnc.clue_count_per_game)
FROM
	game_and_total_clues gnc
GROUP BY
	extract(year from gnc.airdate);
*/
/*
SELECT
	cl_count.gameid, ((fcl_count.num + cl_count.num)) as clue_count_per_game, cl_count.airdate
FROM
	(SELECT
		cl.gameid, count(*) as num, g.airdate
	FROM
		games g left join clues cl on
			(g.gameid = cl.gameid)
	GROUP BY
		cl.gameid, g.airdate) cl_count

	, (SELECT
		fcl.gameid, count(*) as num, g.airdate
	FROM
		games g left join final_clues fcl on
			(g.gameid = fcl.gameid)
	GROUP BY
		fcl.gameid, g.airdate) fcl_count
		
WHERE
	cl_count.gameid = fcl_count.gameid
	and extract(year from cl_count.airdate) = '2012';
*/
/*
SELECT
	cl.gameid, count(*)
FROM
    games g left join clues cl on
		(g.gameid = cl.gameid)
GROUP BY
	cl.gameid;

SELECT
	fcl.gameid, count(*)
FROM
    games g left join final_clues fcl on
		(g.gameid = fcl.gameid)
GROUP BY
	fcl.gameid;

*/
-- How many responses to final jeopardy clues are missing
-- Each contestant with a positive score (above zero) coming into the final jeopardy (i.e.
-- in Round 3) must have a response for the final clue in the database. Exclude in your
-- computation any response from a contestant with a missing final score or a negative
-- score in round 3.
-- If a final clue is missing, exclude any responses to that clue in your computation as well.
/*
SELECT count(*) FROM (
	(SELECT
	   c1.fullname
	   , c1.gameid
	   , count(fr1.gameid) as numfinalresponse
	FROM
	   contestants c1 
	   left join final_responses fr1 on
		  (c1.gameid = fr1.gameid
		   and c1.shortname = fr1.shortname)
	   , games g1
	WHERE
	   g1.gameid = c1.gameid
           and c1.gameid in
		(SELECT
			gameid
		FROM
			final_clues)
	   and (c1.gameid, c1.shortname) in
		(SELECT
			c2.gameid, c2.shortname
		FROM
			contestants c2
			, scores s2
		WHERE
			s2.gameid = c2.gameid
			and s2.shortname = c2.shortname
			and s2.round = '3'
			and s2.score > 0)
	   and extract(year from g1.airdate) = '2015'

	GROUP BY
	   c1.fullname, c1.gameid
	HAVING
	   count(fr1.gameid)=0)) as foo;
*/
/*
SELECT
	count(*)
FROM
	contestants c2 left join final_responses fr2 on
		(c2.gameid = fr2.gameid
			and c2.shortname = fr2.shortname)
	, games g
WHERE
	c2.gameid = g.gameid
	and c2.gameid in
		(SELECT
			gameid
		FROM
			final_clues)
	and (c2.gameid, c2.shortname) in
		(SELECT
			c1.gameid, c1.shortname
		FROM
			contestants c1
			, scores s1
		WHERE
			s1.gameid = c1.gameid
			and s1.shortname = c1.shortname
			and s1.round = '3'
			and s1.score > 0)
	and extract(year from g.airdate) = '2012'
GROUP BY	
	c2.gameid
	, c2.shortname;
*/
-- all final_clues
/*
SELECT
	gameid
FROM
	final_clues
*/
-- contestants with positive score in round 3
/*
SELECT
	contestants.gameid, contestants.shortname
FROM
	constestants c1
	, scores s1
WHERE
	s1.gameid = c1.shortname
	and s1.shortname = s1.shortname
	and s1.round = '3'
	and s1.score > 0
*/	
	
	
	
	
	
	
	
	

	
	