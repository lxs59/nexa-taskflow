FROM python:3.12-slim AS builder

WORKDIR /build

COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim

WORKDIR /app

COPY --from=builder /install /usr/local

RUN groupadd -r taskflow && useradd -r -g taskflow taskflow

COPY --chown=taskflow:taskflow app/ /app/app/

RUN chown taskflow:taskflow /app

USER taskflow

EXPOSE 8085

CMD ["python", "-m", "app.app"]