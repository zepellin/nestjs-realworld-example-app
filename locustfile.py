import time
import random
from faker import Faker
from faker.providers import internet
from locust import HttpUser, task, between

class UserActions(HttpUser):
    wait_time = between(1, 5)

    user_token = ""
    articles = []

    # View user's profile
    @task
    def get_user_profile(self):
        self.client.get(url="/api/user", headers={"Authorization": "Token " + self.user_token})

    # List all articles, get total number (ids) of articles
    @task
    def list_articles(self):
        response = self.client.get(url="/api/articles", headers={"Authorization": "Token " + self.user_token})
        self.articles.extend([article['slug'] for article in response.json()['articles']])

    # User views random few of the available articles
    @task(5)
    def view_article(self):
        self.client.get(url="/api/articles/"+random.choice(self.articles), headers={"Authorization": "Token " + self.user_token})

    # On start, register a new user and retrieve it's authorization token, and lists articles
    def on_start(self):
        fake = Faker()
        fake.add_provider(internet)
        response = self.client.post("/api/users", json={"user": {"username":fake.user_name(), "email": fake.email(), "password":fake.password()}})
        json_response_dict = response.json()
        self.user_token = json_response_dict['user']['token']
        self.list_articles()
