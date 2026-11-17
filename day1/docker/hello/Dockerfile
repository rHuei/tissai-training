FROM python:3.12-slim
WORKDIR /app
COPY . /app
RUN pip install --trusted-host files.pythonhosted.org \
    -r requirements.txt
EXPOSE 80
ENV NAME=World VERSION=v1
CMD ["python", "app.py"]