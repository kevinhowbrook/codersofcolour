FROM python:3.7

RUN useradd wagtail && mkdir /app && chown wagtail /app

WORKDIR /app
ENV PYTHONPATH=/app \
    DJANGO_SETTINGS_MODULE=mysite.settings.production \
    PORT=8000 \
    WEB_CONCURRENCY=3

# Set argument for switching dev/production requirements.
ARG BUILD_ENV

# Port exposed by this container. Should default to the port used by your WSGI
# server (Gunicorn). This is read by Dokku only. Heroku will ignore this.
EXPOSE 8000


COPY ./requirements.txt /app/requirements.txt
RUN pip install --upgrade pip
# Install any needed packages specified in requirements.txt
RUN pip install -r /app/requirements.txt
RUN pip install gunicorn


# Copy the current directory contents into the container at /code/
COPY . /app/
# Set the working directory to /code/
WORKDIR /app/

# Copy gunicorn config overrides.
#COPY gunicorn-conf.py ./

# Collect static. This command will move static files from application
# directories and "static_compiled" folder to the main static directory that
# will be served by the WSGI server.
RUN SECRET_KEY=none django-admin collectstatic --noinput --clear

# Don't use the root user as it's an anti-pattern and Heroku does not run
# containers as root either.
# https://devcenter.heroku.com/articles/container-registry-and-runtime#dockerfile-commands-and-runtime
USER wagtail

# Run the WSGI server. It reads GUNICORN_CMD_ARGS, PORT and WEB_CONCURRENCY
# environment variable hence we don't specify a lot options below.
CMD gunicorn mysite.wsgi:application