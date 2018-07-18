FROM python:3.5.2
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
ADD . ./
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 8000
CMD ["sh","./all_run.sh"]
