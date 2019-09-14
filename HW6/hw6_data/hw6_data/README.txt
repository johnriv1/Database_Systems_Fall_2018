
Note that a copy of this database is created for each student 
in the class database server.

If you want to create this database on your own personal database, you
will need access to the psql interface.

Instructions:

1. Open a terminal.

2. Unzip the file 'hw6_data.dmp.gz' and cd to the same directory as
this file.

3. Create a database for this data. I will call it "hw6"

4. Type the following:

cat hw6_data.dmp | psql hw6

This should create all the tables and the data.
