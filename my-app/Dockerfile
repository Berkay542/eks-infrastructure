FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y build-essential libpq-dev \
    && rm -rf /var/lib/apt/lists/*

ADD ./.aptible /.aptible

WORKDIR /app
ADD requirements.txt /app/

RUN pip install -r requirements.txt
ADD app/ /app/

ENV PORT 5000
EXPOSE 5000
