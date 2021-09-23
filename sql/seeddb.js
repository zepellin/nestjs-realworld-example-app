// Initialize imports
var faker = require('faker');
const { Pool, Client } = require('pg')

// DB connection details
const pool = new Pool({
    user: process.env.TYPEORM_USERNAME || 'docker',
    host: process.env.TYPEORM_HOST || 'postgresdb',
    database: process.env.TYPEORM_DATABASE || 'nestjsrealworld',
    password: process.env.TYPEORM_PASSWORD ||'docker',
    port: process.env.TYPEORM_PORT || 5432,
})

var promises = [];

// Seeding variables
var num_users = 100;
var num_min_articles_per_user = 0;
var num_max_articles_per_user = 17;

// Create users in the DB
for (let i = 0; i < num_users; i++) {
    let username = faker.internet.userName()
    pool.query('INSERT INTO "user" (username,email,bio,image,password) VALUES ($1, $2, $3, $4, $5)', [username, faker.internet.email(), faker.lorem.sentence(), faker.image.image(), faker.internet.password()], (err, res) => {
        promises.push(getId(username));
        console.log("Record written for user", username)
    })
}

// Callback function of create user. Queries DB and fetches ID for the newly created user. Calls InsertArticle function to create random X number articles for the user
function getId(username) {
    return new Promise(function (resolve, reject) {
        pool.query('SELECT id FROM "user" WHERE username = $1', [username], (err, res) => {
            if (res.rowCount == 1) {
                promises.push(insertArticle(res.rows[0].id));
                return resolve(res.rows[0].id)
            }
            else {
                console.log("User", username, "not found")
                return reject("User not found")
            }
        })
    })
};

// Callback function of getId function. Creates between num_min_articles_per_user and num_max_articles_per_user articles per user
function insertArticle(id) {
    return new Promise(function (resolve, reject) {
        for (let i = 0; i < faker.datatype.number({ 'min': num_min_articles_per_user, 'max': num_max_articles_per_user }); i++) {
            pool.query('INSERT INTO "article" ("slug", "title" , "description" , "body" , "created" ,"updated", "tagList", "favoriteCount", "authorId") VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)', [faker.lorem.slug(5), faker.lorem.sentence(), faker.lorem.sentence(), faker.lorem.paragraph(), faker.date.past(5), faker.date.past(3), faker.lorem.sentence(3, 5), faker.datatype.number(10), id], (err, res) => {
                if (res) {
                    console.log("Inserted article for user ID", id)
                    return resolve(id)
                }
                else {
                    console.log(err)
                    return reject(err)
                }
            })
        }
    })
};