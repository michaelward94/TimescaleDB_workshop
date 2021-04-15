# TimescaleDB: Installations and Setup

#### You should have already completed the following before beginning this guide:

- Downloaded and installed Docker desktop
- Launched Docker desktop to make sure that it launches without errors
- Created a DockerHub account

## Installing Windows Terminal (optional)

We will be using windows terminal to run docker commands and a few utilities for timescaledb. Windows terminal lets you open multiple tabs of terminal windows, and you can run powershell, command prompt, or azure cloud shell inside windows terminal.

You can either install Windows Terminal or use Windows Powershell which you should already have. 

Don't forget, you can use the up and down arrow keys to cycle through recently used commands.

If you do not have windows terminal you can install it here: https://www.microsoft.com/en-us/p/windows-terminal/9n0dx20hk701?activetab=pivot:overviewtab

If you are using Mac, you can use the standard Mac terminal.

## Get the TimescaleDB Docker Image & Create a Docker Container for TimescaleDB

Run the following commands in windows terminal, powershell, or mac terminal. Make sure docker desktop is running first!

#### Pull the image from dockerhub:

`Docker pull timescale/timescaledb-postgis`

This command downloads the image we want from DockerHub. This gets us a timescale database built on postgres that also has postgis. (Timescale will be enabled by default but postgis still will have to be created as an extension later)

#### Create container:

`Docker container run -d --name timescaledb -p 5434:5432 -e POSTGRES_PASSWORD=password timescale/timescaledb-postgis`

Remarks on the switches used in this command:
- **-p 5434:5432**: The PostgreSQL server must listen on a specific port for client connections. 5432 is the default Postgres port. We are using 5434 in case we actually have or ever install a native Postgres server. 5434 is mapped to port 5432 in the container.

- **--name timescaledb**: The name timescaledb is arbitrary. You can use any name for the container that you like. You will need to reference this name later.

- **-d**: -d designates the container to run as a daemon process. A daemon is a computer process that runs in the background and isn't under direct control of the interactive user.

- **-e**: -e is where you set environment variables. We are using it to set the password for our database. You can make it whatever you want as long as you remember it.

- **timescale/timescaledb-postgis**: This is the name of the image that we are running inside the container

- There are many more switches you can use with `Docker container run` If you're interested, you can see them all here - https://docs.docker.com/engine/reference/commandline/container_run/

#### Running your container:

`Docker start timescaledb`

#### Stopping your container:

`Docker stop timescaledb`

#### You now have a running TimescaleDB instance on port 5434. We will next cover how to create a database in your TimescaleDB instance, and connect that database to DBeaver.

# Creating a database for TimescaleDB

## Option 1: psql shell

#### What is psql shell?

- psql shell is an interactive terminal for working with postgres. Some of you may have used it before. If you haven't seen it before, don't be intimidated, we are only running a few commands in psql shell to make a new database and add postgis an extension.

Start by opening a new tab in your windows terminal, or opening a new terminal instance if you are using powershell or mac terminal.

We are going start an instance of psql shell inside our terminal using the following command:

`docker exec -it timescaledb psql -U postgres`

Remarks on this command:
- **-it**: This is where you need to reference the name that you gave to your container, followed by psql
- **-U postgres**: This is the default user, and the user that we will be using to connect to psql shell

You may be prompted to enter the password you created earlier. Your interface should now look like this:

```
psql (9.6.13)
Type "help" for help.

postgres=#
```

If you see this, you are now in psql shell. To view all of the databases that exist in your timescale instance just run:

`\l`

Right now, you should see nothing because you haven't created any databases yet. To make a new database, run:

`Create database timescale_workshop;`

Now try running `\l` again. You should now have one database called timescale_workshop owned by postgres. To connect to the database you just created, run:

`\c timescale_workshop;`

Now your interface should look like:

```
You are now connected to database "timescale_workshop" as user "postgres".
timescale_workshop=#
```

You are now inside the database you just created, and can run sql statements just like how you would in a sql script inside DBeaver. We are going to run one statement:

`Create extension if not exists postgis;`

If the extension didn't exist already, the interface should give you confirmation by returning `CREATE EXTENSION`. If the extension already existed, it should return that it skipped creating the extension.

You can now connect your newly created TimescaleDB database to any Postgres client, but we will connect it to DBeaver. If you used the configurations mentioned in this tutorial, your connection settings should be as follows:

```
Host: localhost
Port: 5434
Database: timescale_workshop
User: postgres
Password: password
```

You may need to use different connection settings if you named your database something else, used a different password, a different port, or a different user.

## Option 2: Create a new database by connecting to the default database in DBeaver

Rather than using the command prompt interface, you can connect to the default database using DBeaver.

In DBeaver, create new database connection:

```
Host: localhost
Port: 5434
Database: postgres
Username: postgres
Password: password
```

This will connect you to the default database. This default database is used to manage the database cluster and will not be the database that we will be working in.

The reason that we are connecting to the default database is so that we can create a new database that we will work in. Open a new sql script in DBeaver and run the commands:

`Create database timescale_workshop;`

`Create extension if not exists postgis;`

Now we can connect to this new database and disconnect from the default database. Create a new DBeaver connection:

```
Host: localhost
Port: 5434
Database: timescale_workshop
Username: postgres
Password: password
```

## Preparing to Load data

To load data efficiently into your timescale database there are a few more tools that you need. Start by downloading and installing Go runtime from the following link:

Go runtime: https://golang.org/doc/install

Go runtime is an open source programming language. We are just using it for one of the commands it adds to your terminal.

Once you have downloaded and installed Go runtime, run the following command in your terminal:

`go get github.com/timescale/timescaledb-parallel-copy/cmd/timescaledb-parallel-copy`

This is going to download a command line utility that allows for parallel copying of CSV data into a TimescaleDB hypertable. It will allow for extremely fast bulk insertion of data.

## Download the CSV file and ETL script and put it in a reasonable directory

The CSV data and ETL script that we will use in the workshop can be found on the main branch of the github repository: https://github.com/michaelward94/TimescaleDB_workshop

Please download the data and unzip it into a reasonable folder.

## Run the ETL script

Open the ETL script in DBeaver and modify the search path if needed.

Run the ETL script to create the tables needed.

## Use Timescale Parallel Copy to load the data

Open your terminal (either powershell, windows terminal, or terminal for mac)

We are going to use a command similar to ogr2ogr to load the data:

```
timescaledb-parallel-copy --db-name timescale_workshop
--connection "host=localhost user=postgres password=password port=5434 sslmode=disable"
--table stops -schema stop_frisk --file 'complete path of csv goes here'
--workers 4 --reporting-period 30s -skip-header
```

You will need to modify the `--file` switch to include the complete path to where you saved the csv file.

You may need to modify the input to the switches if you used a different database name, schema name, or password

*Important* : This command as shown has line breaks but must be executed as a single line in your terminal
