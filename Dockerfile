FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY . /app/

ENV PORT=3000
EXPOSE 3000

# If app.py contains a Flask app called `app`
CMD ["gunicorn", "--bind", "0.0.0.0:3000", "app:app", "--workers", "2"]