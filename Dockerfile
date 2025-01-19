FROM dorowu/ubuntu-desktop-lxde-vnc:latest

# Add Google Chrome repository key
RUN apt-get install -y wget && \
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -

# Install tzdata for timezone support
RUN apt-get update && apt-get install -y tzdata && \
    rm -rf /var/lib/apt/lists/*

# Create script for timezone setup
COPY <<'EOF' /usr/local/bin/setup-timezone.sh
#!/bin/bash
if [ ! -z "$TZ" ]; then
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
    echo "$TZ" > /etc/timezone
    dpkg-reconfigure -f noninteractive tzdata
fi
EOF
RUN chmod +x /usr/local/bin/setup-timezone.sh

# Add timezone setup to startup
COPY <<'EOF' /etc/cont-init.d/99-timezone
#!/usr/bin/with-contenv bash
/usr/local/bin/setup-timezone.sh
EOF
RUN chmod +x /etc/cont-init.d/99-timezone

# Update google-chrome
RUN apt install -y gpg-agent \
    && curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add \
    && curl -LO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && (dpkg -i ./google-chrome-stable_current_amd64.deb || apt-get install -fy) \
    && rm google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.11 and pip
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y \
    python3.11-full \
    python3.11-venv \
    python3.11-distutils \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment for Python 3.11
RUN python3.11 -m venv /opt/venv

# Install packages in virtual environment without changing system Python
RUN /opt/venv/bin/pip install --no-cache-dir browser-use && \
    /opt/venv/bin/pip install playwright && \
    /opt/venv/bin/playwright install && \
    /opt/venv/bin/playwright install-deps

# Set environment variables for browser-use
ENV PYTHONUNBUFFERED=1
ENV DISPLAY=:1.0

# Add script to use Python 3.11 environment when needed
COPY <<'EOF' /usr/local/bin/browser-use
#!/bin/bash
source /opt/venv/bin/activate
python "$@"
EOF
RUN chmod +x /usr/local/bin/browser-use
