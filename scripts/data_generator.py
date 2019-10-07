import datetime
from faker import Faker
from google.cloud import pubsub_v1
import json
import random
import requests
import time

fake = Faker()

# Generate company data using seeded faker to repeat companies
def generate_companies(x):
    fake.seed(7)
    company_data = {}
    for i in range(x):
        company_data[i] = {}
        company_data[i]['name'] = fake.company()
        company_data[i]['objects'] = random.randint(300,3000)
        # print(company_data[i]['name'])
    fake.seed(None)
    return company_data

def generate_data(company):
    alert_data = {}
    # Generate current time with UTC timestamp
    alert_data['time'] = datetime.datetime.utcnow().replace(tzinfo=datetime.timezone.utc).isoformat()
    alert_data['name'] = company['name']
    alert_data['objects'] = company['objects']
    alert_data['red'] = random.randint(0,100)
    alert_data['orange'] = random.randint(0,100)
    alert_data['pause'] = random.randint(0,100)
    return alert_data

def publish_message(message):
    project_id = "datacom-operations-two"
    topic_name = "alert_data"

    # Publish to google pub/sub
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, topic_name)
    data=message.encode('utf-8')  # data must be a bytestring.

    # When you publish a message, the client returns a future.
    future = publisher.publish(
        topic_path, data
    )

    print(future.result())

if __name__ == '__main__':
    REST_API_URL = 'https://api.powerbi.com/beta/866c7a4c-8a59-4bd3-ad9f-8512a581efc0/datasets/f25fcc4b-09eb-4539-85a1-5383bb5681ac/rows?key=29PDCxLBxUL1Ixtze9Tb76DBQmj5FKBvqMWFmESqcyijMl%2F16mMg3UNsDXQSXNck%2Fuyg40ym3nG7L8g7bekSYw%3D%3D'
    companies = generate_companies(10)

    while True:
        for x in companies:
            data = generate_data(companies[x])
            data_json = json.dumps(data)
            print(data_json)
            publish_message(data_json)

        time.sleep(60)
