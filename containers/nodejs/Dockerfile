FROM node:20-slim

# Create a non-root user for security
RUN useradd -m sandboxuser
WORKDIR /code
USER sandboxuser

CMD ["node", "/code/solution.js"]