FROM python:3.12-slim
LABEL maintainer="Luciano Parruccia <parruccia@yahoo.com.ar>"
LABEL version="2.0"
LABEL description="fabrica de pastas"

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /code

COPY requirements.txt .
RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && rm requirements.txt

COPY ./src /code

ENV TZ=America/Cordoba
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /timezone

CMD ["gunicorn", "--bind", ":8000", "--workers", "3", "app.wsgi"]
