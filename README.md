
# ![Node/Express/Mongoose Example App](project-logo.png)

Putting the homework documentation here, as it's probabaly the easiest to consume. I'll describe each point in the assignment individually here, from more of a logical explanation and motivation point of view, files in which the work was done are linked here with more comments describing more technical aspect of thinking.

## 1. Change the ORM setup to use PostgreSQL instead of MySQL
According to [TypeORM documentation](https://typeorm.io/#/undefined/installation), installed type orm PG postgres driver `npm install typeorm pg --save` and updated configuration in ormconfig.json. Then the standard node.js `npm install` and `npm start` command get the app running with a PG backed DB.

 - The productionized version should probably be provided configuration as environment variables (done in later steps for cloud deployment).
 - Haven't touched on DB setup here, explained in developer setup further below.

## 2. Write a seed script to load bulk records into the database
The thinking behind a seed script was to get the DB ready for a load testing later. [The script](sql/seeddb.js) is a simple node script that connects to a database, creates a specified number of users and a specified semi random number of articles. The script uses [faker.js](https://github.com/marak/Faker.js/) library to generate user and article data. 

 - Written in node, as the app is node.js app, could be conventient is this is a solely Node env, from the app cointainer by the developer (see below) etc.
 - Doesn't contain facility to load data from file etc, thought that would be redundant since I am importing random data for load testing anyway. Could be extended to do that. 
 - The script uses either app's DB connection details (from ENV) or default config.

## 3.  Setup Docker for Local Development

For this one I went with docker compose, as it allows for easy spin up and down of developer environments. The [docker-compose file](docker-compose.yaml) file is included, containing the NestJs application service and a Postgresql database, both fetching their configuration from an [.env](.env) file. 
 1. Documentation/developer instruction would then in the simplest form be
	 - Make sure you've got docker running on your machine
	 - Run `docker compose up --build -d`
	 - You app will be exposed on `localhost:3000`
	 - If seeding DB with random data is desired, this can be done using the seed script like `docker exec <container_id> node sql/seeddb.js`
 2. When database is initialized without a previous state an [initialization script](sql/create-database.sql) is ran to create a database for the application to use. 
## 4.  Write a benchmark script to test the performance of at least 1 endpoint
For this one I went with [Locust](https://locust.io/), and open source load testing tool. It allows in a python native way to test performance of a web application and takes care of the statistics and metrics side of things. 
The [locust configuration file](locustfile.py) for this test contains actions for a test user that:

- Registers `POST /api/users` with randomly generated user data. The user retrieves it's authentication token that will be used for all subsequent HTTP calls.
- Fetches user profile `GET /api/user`
- Fetches a list of all articles `GET /api/articles`
- Fetches 5 randomly selected articles from the list retrieved above using `GET /api/articles/<article_slug>`

The test can be run in an environment with locust installed as `/home/martind/.local/bin/locust --users=200 --spawn-rate=10 --run-time=60 --host=http://localhost:3000 -f locustfile.py` and metrics and statistics can be retrieved from the UI (by default localhost:8089) or command line output. 

## 5.  Configure continuous integration in your GitHub repo to Deploy the application using Terraform to a cloud provider of your choice
This was done by utilising Github actions, secrets and terraform. [Github workflow file](.github/workflows/build.yml) contains following:

- The application docker image is built
- The image is then push to Google Cloud container registry
- The application is then deployed using terraform to a Google Cloud Run 

The steps above only happen on pushes to the `master` branch, the extended idea here would be to facilitate GitOps workflow where pull requests would be reviewed, tested and approved before code is pushed into a protected branch and deployed from there. 

- Terraform state is held in a GCS bucket in the same Google Cloud project as the application.
- There are many way of doing this, one could also doing this on Google Cloud side by linking the Github repository and running build/deploy from there. 
- Database details (host, password etc) are provided to the application via environmental variables in terraform.
- Image tag to deploy is provided to terraform from Github provided variables, in this case commit SHA.
- Secret (DB password) is provided via it's store in Google Cloud secrets manager, where it is managed by terraform (from Github secrets).

## 6.  Document why you chose the cloud provider that you did
I've chosed Google Cloud as a cloud provider for this excersise for following reasons:

- Ease of set up (and I already had an account :-)
- Full on support in terraform via it's provider
- Managed service for the database (used [Cloud SQL for PostgreSQL](https://cloud.google.com/sql/docs/postgres) in this instance) 
- Managed service for containerized workloads (Cloud Run in this instance)
- Managed container registry (GCR)
- Managed secret store (Secrets Manager)

Architecturaly, I was following principles:

- Managed services first - cheap, typically very limited maintenance required, able to focus on business on business logic/requirements
- Serverless first - Removes complexity of maintenance of hosting environment, extremely easy to use and maintain, only responsible for the very top of cloud hosting shared responsibility model. 

Apart from commoditized services (DB, container registry, secrets etc), important consideration in the decision to go with Google Cloud for this assignment was Google Cloud having cloud run service (sort of a fargate equivalent, without the cluster etc). It allows for scaling to 0, pay per use (and other models), HTTPS with own domain, traffic splitting, support for secret engine, and "one click/terraform" deployment. All of this allow for very easy development (per revision subdomains), cost effectivness, and minimal mantenance.  