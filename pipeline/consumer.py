"""Full pipeline consumer to read from Kafka topic and load into database."""

from datetime import datetime, timedelta
from os import environ as ENV
import argparse
import logging
import json

from confluent_kafka import Consumer, Message
from dotenv import load_dotenv

from psycopg2 import connect, sql
from psycopg2 import Error
from psycopg2.extensions import connection


def setup_argparse() -> argparse.ArgumentParser:
    """Return a parser with all arguments."""
    parser = argparse.ArgumentParser()

    parser.add_argument("-l",
                        "--load",
                        action="store_false",
                        help="Skip loading the transformed data into the database "
                        "(loading runs by default).")

    parser.add_argument("-ldb",
                        "--local_db",
                        action="store_true",
                        help="Use the local database (default is AWS RDS).")

    parser.add_argument("-lr",
                        "--load_review",
                        action="store_false",
                        help="Skip loading the local review data into the database "
                        "(loading runs by default).")

    parser.add_argument("-li",
                        "--load_incident",
                        action="store_false",
                        help="Skip loading the local incident data into the database "
                        "(loading runs by default).")

    return parser


def get_consumer() -> Consumer:
    """Return a Consumer."""
    return Consumer({
        "bootstrap.servers": ENV["BOOTSTRAP_SERVERS"],
        'security.protocol': ENV["SECURITY_PROTOCOL"],
        'sasl.mechanisms': ENV["SASL_MECHANISM"],
        'sasl.username': ENV["USERNAME"],
        'sasl.password': ENV["PASSWORD"],
        "group.id": ENV["GROUP_ID"],
        "auto.offset.reset": ENV["AUTO_OFFSET"]
    })


def get_db_connection() -> connection:
    """Return database connection."""
    try:
        conn = connect(
            user=ENV["DATABASE_USERNAME"],
            password=ENV["DATABASE_PASSWORD"],
            host=ENV["DATABASE_IP"],
            port=ENV["DATABASE_PORT"],
            database=ENV["DATABASE_NAME"]
        )
        return conn
    except Error as e:
        logging.error(f"Error connecting to database: {e}")
        return None


def get_local_db_connection() -> connection:
    """Return database connection."""
    try:
        conn = connect(
            user=ENV["LOCAL_DATABASE_USERNAME"],
            password=ENV["LOCAL_DATABASE_PASSWORD"],
            host=ENV["LOCAL_DATABASE_IP"],
            port=ENV["LOCAL_DATABASE_PORT"],
            database=ENV["LOCAL_DATABASE_NAME"]
        )
        return conn
    except Error as e:
        logging.error(f"Error connecting to local database: {e}")
        return None


def check_for_correct_columns(data: dict) -> bool:
    """Check if the data has the correct keys."""
    required_columns = {"at", "site", "val"}

    if not required_columns.issubset(data.keys()):
        return False

    if data["val"] == -1 and "type" not in data.keys():
        return False

    return True


def check_for_correct_values(data: dict) -> bool:
    """Check if the data has the correct values."""
    try:
        timestamp = datetime.fromisoformat(data["at"])

        if timestamp > datetime.now(timestamp.tzinfo) + timedelta(seconds=0.9):
            logging.warning("Timestamp is in the future: %s", data["at"])
            return False

        hour = timestamp.hour
        minute = timestamp.minute

        before_opening = (hour < 8) or (hour == 8 and minute < 45)
        after_closing = (hour > 18) or (hour == 18 and minute > 15)

        if before_opening or after_closing:
            return False

        if not 0 <= int(data["site"]) <= 5:
            return False

        if not -1 <= int(data["val"]) <= 4:
            return False

        if int(data["val"]) == -1:
            if int(data["type"]) not in [0, 1]:
                return False

        return True
    except ValueError:
        return False


def transform_message(msg: Message) -> dict:
    """Transform a Kafka message into a dictionary."""
    data = json.loads(msg.value())
    logging.info("Message contains the following data: %s", data)

    logging.info("Checking for null values...")
    for val in data.values():
        if val is None:
            logging.warning("Message had null values")
            return {}

    logging.info("Checking for missing columns...")
    if not check_for_correct_columns(data):
        logging.warning("Message had missing columns")
        return {}

    logging.info("Checking for incorrect values...")
    if not check_for_correct_values(data):
        logging.warning("Message had incorrect values")
        return {}

    data["site"] = int(data["site"])

    if data["val"] != -1:
        logging.info("Review data found")
        review_data = {
            "review_at": data["at"],
            "exhibition_id": data["site"] + 1,
            "rating_id": data["val"] + 1
        }

        return review_data
    else:
        logging.info("Incident data found")
        incident_data = {
            "incident_at": data["at"],
            "exhibition_id": data["site"] + 1,
            "incident_type_id": data["type"] + 1
        }
        return incident_data


def insert_data(conn: connection, data: dict, table_name: str) -> None:
    """Inserts the data into the database."""
    with conn.cursor() as cur:
        columns = sql.SQL(', ').join(
            sql.Identifier(col) for col in data.keys()
        )

        placeholders = sql.SQL(', ').join(
            sql.Placeholder() for _ in data.values()
        )

        query = sql.SQL("INSERT INTO {} ({}) VALUES ({})").format(
            sql.Identifier(table_name),
            columns,
            placeholders
        )

        cur.execute(query, tuple(data.values()))
        conn.commit()


def load(args: argparse.Namespace, data: dict) -> None:
    """Loads the data into the database."""

    if args.local_db:
        logging.info("Using local database connection.")
        conn = get_local_db_connection()
    else:
        logging.info("Using remote database connection.")
        conn = get_db_connection()

    if "review_at" in data:
        if args.load_review:
            logging.info("Loading review data into database.")
            insert_data(conn, data, "review")
        else:
            logging.info("Loading review data skipped.")
    else:
        if args.load_incident:
            logging.info("Loading incident data into database.")
            insert_data(conn, data, "incident")
        else:
            logging.info("Loading incident data skipped.")


def consume_messages(consumer: Consumer, topic: str, args: argparse.Namespace) -> None:
    """Consume all messages from a topic."""
    # Subscribe to topic
    consumer.subscribe([topic])

    # Feed
    logging.info("Starting feed loop...")
    while True:
        msg = consumer.poll(1)

        if msg:
            logging.info("─"*100)
            logging.info("Received message: %s", msg)

            data = transform_message(msg)

            if data:
                logging.info("Transformed message: %s", data)
                if args.load:
                    logging.info("Loading data into database")
                    load(args, data)
            else:
                logging.info("Message had incorrect data, no data saved")


if __name__ == "__main__":

    parser = setup_argparse()
    args = parser.parse_args()

    load_dotenv()

    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('./logs/pipeline.log')
        ]
    )

    logging.info("─"*100)
    logging.info("Pipeline started with arguments: %s", args)
    logging.info("Getting consumer from .env details")
    consumer = get_consumer()

    topic = "lmnh"
    logging.info("Receiving messages from '%s' topic", topic)
    consume_messages(consumer=consumer, topic=topic, args=args)
