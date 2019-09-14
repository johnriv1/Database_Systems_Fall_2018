
Using the data dump file requires access to psql interface.

Instructions:

1. Open a terminal.

2. Unzip the file 'hw4_data.dmp.gz' and cd to the same directory as
this file.

3. Create a database for this data. I will call it "hw4"

4. Type the following:

cat hw4_data.dmp | psql hw4

This should create all the tables and the data.
