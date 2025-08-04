FROM dreamhackofficial/web3-base:latest

COPY ./app/ /app/

COPY ./deploy/config.yaml /app/
COPY ./deploy/remappings.txt /app/
COPY ./deploy/src/ /app/src/
COPY ./deploy/lib/ /app/lib/
COPY ./deploy/verifier.py /verifier.py

COPY ./deploy/script/ /app/script/
COPY ./private/flag.txt /app/
COPY ./deploy/build.sh /app/

RUN /app/build.sh

ENTRYPOINT ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "1337"]
