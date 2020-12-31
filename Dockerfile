FROM python:3.7

RUN useradd wagtail && mkdir /app && chown wagtail /app

WORKDIR /app

# Set default environment variables. They are used at build time and runtime.
# If you specify your own environment variables on Heroku or Dokku, they will
# override the ones set here. The ones below serve as sane defaults only.
#  * PATH - Make sure that Poetry is on the PATH
#  * PYTHONUNBUFFERED - This is useful so Python does not hold any messages
#    from being output.
#    https://docs.python.org/3.8/using/cmdline.html#envvar-PYTHONUNBUFFERED
#    https://docs.python.org/3.8/using/cmdline.html#cmdoption-u
#  * PYTHONPATH - enables use of django-admin command.
#  * DJANGO_SETTINGS_MODULE - default settings used in the container.
#  * PORT - default port used. Please match with EXPOSE so it works on Dokku.
#    Heroku will ignore EXPOSE and only set PORT variable. PORT variable is
#    read/used by Gunicorn.
#  * WEB_CONCURRENCY - number of workers used by Gunicorn. The variable is
#    read by Gunicorn.
#  * GUNICORN_CMD_ARGS - additional arguments to be passed to Gunicorn. This
#    variable is read by Gunicorn
ENV PYTHONPATH=/app \
    DJANGO_SETTINGS_MODULE=mysite.settings.production \
    PORT=8000 \
    WEB_CONCURRENCY=3 \
    GUNICORN_CMD_ARGS="-c gunicorn-conf.py --max-requests 1200 --access-logfile - --timeout 25"

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