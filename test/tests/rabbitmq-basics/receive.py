#!/usr/bin/env python3
import pika

# https://www.rabbitmq.com/tutorials/tutorial-one-python.html

connection = pika.BlockingConnection(pika.ConnectionParameters('rabbitmq'))
channel = connection.channel()

channel.queue_declare(queue='hello')

def callback(ch, method, properties, body):
    print(body.decode('utf-8'))
    connection.close()

channel.basic_consume(queue='hello',
                      auto_ack=True,
                      on_message_callback=callback)

channel.start_consuming()
