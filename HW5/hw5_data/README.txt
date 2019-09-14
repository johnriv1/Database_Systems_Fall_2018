
Using the data dump file requires access to psql interface.

Instructions:

1. Open a terminal.

2. Unzip the file 'jeopardy_db.dmp.gz' and cd to the same directory as
this file.

3. Create a database for this data. I will call it "jeopardy"

4. Type the following:

cat jeopardy_db.dmp | psql jeopardy

This should create all the tables and the data.
