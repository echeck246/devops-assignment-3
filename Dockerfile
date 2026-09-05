# ==============================================================================
# Dockerfile - Lightweight Container for DevOps Diagnostic Application
# Part of DevOps Assignment 3: CI/CD Pipeline with GitHub Actions
# ==============================================================================

FROM alpine:3.20

LABEL maintainer="Emmanuel Oniyide <emmanueloniyide438@gmail.com>" \
      description="DevOps Automation and Diagnostic CLI" \
      version="1.0.0"

# Install minimal required packages
RUN apk add --no-cache \
        bash \
        curl \
        iputils \
        bind-tools \
        netcat-openbsd \
        util-linux \
        coreutils \
        procps

# Create unprivileged application user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy application files
COPY app/ /app/

# Set file permissions and ownership
RUN chmod +x /app/*.sh && \
    chown -R appuser:appgroup /app

USER appuser

ENTRYPOINT ["/app/app.sh"]
CMD ["help"]
