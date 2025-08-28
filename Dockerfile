FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    HOME=/tmp \
    XDG_CACHE_HOME=/tmp/.cache \
    SELENIUM_MANAGER_CACHE_DIR=/tmp/selenium \
    TMPDIR=/tmp \
    CHROME_BINARY=/usr/bin/chromium \
    CHROMEDRIVER=/usr/bin/chromedriver \
    CHROME_EXTRA_ARGS="--no-sandbox --disable-dev-shm-usage --disable-gpu --window-size=1920,1080 --headless=new"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        chromium chromium-driver \
        fonts-liberation \
        libgbm1 libnss3 libxss1 libasound2 libxshmfence1 \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/downloaded_files /tmp/.cache /tmp/selenium && \
    chmod -R 777 /app/downloaded_files /tmp/.cache /tmp/selenium

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN python -c "import os, sysconfig, pathlib; site=pathlib.Path(sysconfig.get_paths()['purelib']); p=site/'seleniumbase'/'drivers'; print('Fixing perms under:', p); p.mkdir(parents=True, exist_ok=True); os.system(f'chmod -R a+rwX {p}')"

RUN chmod a+rx /usr/bin/chromium /usr/bin/chromedriver

WORKDIR /app
COPY . /app

CMD ["gunicorn","-w","1","--threads","1","-k","uvicorn.workers.UvicornWorker","--bind","0.0.0.0:8080","app.main:app"]
