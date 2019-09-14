
DROP TABLE final_responses ;
DROP TABLE final_clues ;
DROP TABLE responses ;
DROP TABLE clues ;
DROP TABLE scores ;
DROP TABLE contestants ;
DROP TABLE games ;

-- Each game is in a season, given by showid
CREATE TABLE games
     ( showid INT
       , gameid INT
       , airdate DATE
       , PRIMARY KEY (gameid)
     ) ;

-- Each contestant is identified by a shortname, which is unique for a
-- game. 

CREATE TABLE contestants
     ( gameid INT 
       , fullname  VARCHAR(100)
       , description VARCHAR(255)
       , shortname   VARCHAR(100)
       , PRIMARY KEY (gameid, shortname)
       , FOREIGN KEY (gameid) REFERENCES games(gameid)
     ) ;

-- The overall scores of each contestants after different rounds
-- of the game.
-- Rounds '1', '2' are in the first stage called the 'Jeopardy' stage,
-- Round '3' is after 'Double Jeopardy' before 'Final Jeopardy'.
-- Round 'Final Score' is the actual score of each person
-- Round 'Coryat Score' is the hypothetical score without the bets
-- Round '6' is an error, which needs to be identified later.

CREATE TABLE scores
      ( gameid INT
        , shortname VARCHAR(100)
	, score INT
	, round  VARCHAR(20)
	, PRIMARY KEY (gameid, shortname, round)
	, FOREIGN KEY (gameid, shortname)
	  REFERENCES contestants(gameid, shortname)
      ) ;		
	
-- Each game has many clues, clue is the question, and correct_answer is the answer
-- value is the dollar value of the clue: amount player wins/looses
-- for correct, incorrect answers
-- category is the named of the category
-- cat_type is one of: 'J': 'Jeopardy' round and 'DJ': 'Double Jeopardy' round
-- isdd is true if the question was a double jeopardy question

CREATE TABLE clues
     ( gameid INT
       , clueid  INT
       , clue    TEXT
       , value   INT  
       , category  VARCHAR(255)
       , cat_type  VARCHAR(10)
       , isdd      BOOLEAN
       , correct_answer VARCHAR(255)
       , PRIMARY KEY (gameid, clueid)
       , FOREIGN KEY (gameid) REFERENCES games(gameid)
      ) ;

-- Each contestant can answer a clue, if the answer is wrong,
-- another contestant can answer. This relation stores all
-- contestants who gave a response (but not what they said).
-- If there is no correct answer for a question here, it means
-- that no contestant answered the question correctly.

CREATE TABLE responses
      ( gameid  INT
        , clueid  INT
	, shortname VARCHAR(255)
	, iscorrect BOOLEAN
	, PRIMARY KEY (gameid, clueid, shortname)
	, FOREIGN KEY (gameid, clueid) REFERENCES clues(gameid, clueid)
	, FOREIGN KEY (gameid, shortname)
	  REFERENCES contestants(gameid, shortname)
      ) ;

-- At the end of the game, there is a single question/clue called
-- the 'Final Jeopardy'. This relation stores the clues for this
-- specific round. There is no dollar value attached to these questions.

CREATE TABLE final_clues
     ( gameid INT
       , clue    TEXT
       , category  VARCHAR(255)
       , correct_answer VARCHAR(255)
       , PRIMARY KEY (gameid)
       , FOREIGN KEY (gameid) REFERENCES games(gameid)
      ) ;
      

-- For the 'final jeopardy', all contestants give an answer and a bet
-- The bet is the dollar amount the contestant will win/loose if they
-- answer correctly. Only contestants with positive winnings/scores
-- at round '3' can participate. This relation stores the bets and
-- whether each person scored correctly or not.

CREATE TABLE final_responses
      ( gameid  INT
	, shortname VARCHAR(255)
	, iscorrect BOOLEAN
	, bet   FLOAT -- VARCHAR(10)
	, PRIMARY KEY (gameid, shortname)
	, FOREIGN KEY (gameid, shortname)
	  REFERENCES contestants(gameid, shortname)
      ) ;

