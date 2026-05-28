FROM python:3.11-slim

# Create a non-root user for security
RUN useradd -m sandboxuser
WORKDIR /code
USER sandboxuser

CMD ["python", "/code/solution.py"]