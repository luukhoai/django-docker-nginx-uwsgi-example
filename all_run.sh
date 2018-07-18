#!/usr/bin/env bash
python manage.py collectstatic && python manage.py migrate && uwsgi --socket :8000 --enable-threads --thunder-lock --ini uwsgi.ini