#Build stage used to install dependencies
FROM python:3.12-slim@sha256:5e2bdb1b0d542d5039cffb8181c65930093949194a65c365dfb1b0fe13a4fa5b AS builder
WORKDIR /app

#A virtual env is created to keep all installed packages in one folder
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH" 

COPY app/requirements.txt .
#Installs all packages needed from the requirements file and it is not cached 
#   so that there aren't extra download files in the image keeping it smaller.
RUN pip install --no-cache-dir -r requirements.txt

# ---------- Stage 2: runtime ---------
FROM python:3.12-slim AS runtime
 
# PYTHONDONTWRITEBYTECODE: reduces the image size because it stops small compiled cache files from being stored
# PYTHONUNBUFFERED: send logs straight out so they show up in CloudWatch.
# PATH: use the virtual environment copied from the builder stage.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"
WORKDIR /app
# Bring in the packages from the builder stage...
COPY --from=builder /opt/venv /opt/venv
# ...then the app code. Only the files the app needs are copied, and they're
# owned by the app user.
COPY --chown=app:app app/main.py app/index.html ./
# Port 8080, not 80: a non-root user isn't allowed to listen on ports below 1024.
EXPOSE 8080
# Setup an app user so the container doesn't run as the root user
RUN useradd app
USER app


CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]