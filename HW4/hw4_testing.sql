SELECT
   count(*) as c_LeftJoin_r
   , count(c1.gameid) as c_count_in_c_LeftJoin_r
   , count(r1.gameid) as r_count_in_c_LeftJoin_r
   , count(fr1.gameid) as fr_count_in_c_LeftJoin_r
FROM
   contestants c1 left join responses r1 on
      (c1.gameid = r1.gameid
       and c1.shortname = r1.shortname)

   left join final_responses fr1 on
      (c1.gameid = fr1.gameid
       and c1.shortname = fr1.shortname)

   , games g1

WHERE
   g1.gameid = c1.gameid;



SELECT
   count(r1.gameid)
   , count(fr1.gameid)
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

GROUP BY
   c1.fullname, c1.gameid;


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

GROUP BY
   c1.fullname, c1.gameid
HAVING
   count(r1.gameid)=0
   and count(fr1.gameid)=0;
   
---------------------------------------------------------------

SELECT
g1.gameid
, c1.fullname
, r1.iscorrect
, fr1.iscorrect
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
and g1.gameid = 4041;

SELECT
g1.gameid
, c1.fullname
, r1.iscorrect
, fr1.iscorrect
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
and g1.gameid = 4511;

SELECT
g1.gameid
, c1.fullname
, r1.iscorrect
, fr1.iscorrect
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
and g1.gameid = 4014;

SELECT
g1.gameid
, c1.fullname
, r1.iscorrect
, fr1.iscorrect
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
and g1.gameid = 4382;