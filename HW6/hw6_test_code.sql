drop function parsingreport(int);
drop trigger scores_trigger on scores2 ;
drop function scores_trigger_f() cascade;
drop table follows;
drop table contestants2 ;
drop table scores2;


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

select 'Testing results of problem 1: Test 1 (num tuples with iswinner=True)';

select count(*) from contestants2 where iswinner=True;

select 'Testing results of problem 1: Test 2 (games with more than 1 winner)';

select gameid, count(*) from contestants2 where iswinner=True group by gameid having count(*)>1;

SELECT 'Problem 2';

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

select 'testing problem 2 results: Test 1 (select count(*) from follows)';

select count(*) from follows ;

select 'testing problem 2 results: Test 2 (follows tuples for games more than 3 days apart)';

select f.gameid1,f.gameid2 from follows f, games g1, games g2
       where f.gameid1=g1.gameid and f.gameid2=g2.gameid
             and g2.airdate-g1.airdate>3;

SELECT 'Problem 3';

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


select 'Testing results of problem 3: Test 1 (gameid=3913)';


select shortname, iswinner from contestants2 where gameid=3913;
select shortname, score
from scores2
where gameid=3913 and round='Final Score';

--- this should change the winners through the trigger
update scores2   
set score=28805
where round='Final Score'
      and gameid=3913
      and shortname='Rosanne';


select shortname, score
from scores2
where gameid=3913 and round='Final Score';

select 'Testing results of problem 3: Test 2 (gameid: 4056)';


select shortname, iswinner from contestants2 where gameid=4056;
select shortname, score
from scores2
where gameid=4056 and round='Final Score';

--- this should change the winners through the trigger
update scores2
set score=22000
where round='Final Score'
      and gameid=4056
      and shortname='Tim';

select shortname, iswinner from contestants2 where gameid=4056;
select shortname, score
from scores2
where gameid=4056 and round='Final Score';


SELECT 'Problem 4';

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


select 'Testing problem 4: Test 1 (year 2012)';

select parsingreport(2012) ;

select 'Testing problem 4: Test 2 (year 2013)';

select parsingreport(2013) ;

select 'Testing problem 4: Test 3 (year 2014)';

select parsingreport(2014) ;

select 'Testing problem 4: Test 4 (year 2015)';

select parsingreport(2015) ;

select 'Testing problem 4: Test 5 (year 2016)';

select parsingreport(2016) ;
