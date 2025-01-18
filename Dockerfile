FROM dorowu/ubuntu-desktop-lxde-vnc:latest

RUN sed -i 's#http://archive.ubuntu.com/ubuntu/#mirror://mirrors.ubuntu.com/mirrors.txt#' /etc/apt/sources.list;

# Set timezone to JST
RUN apt-get update && apt-get install -y tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    echo "Asia/Tokyo" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    rm -rf /var/lib/apt/lists/*
ENV TZ=Asia/Tokyo

# Update google-chrome
RUN apt install -y gpg-agent \
    && curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add \
    && curl -LO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && (dpkg -i ./google-chrome-stable_current_amd64.deb || apt-get install -fy) \
    && rm google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

# Install Python and pip
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install browser-use and its dependencies
RUN python3 -m pip install --no-cache-dir browser-use

# Install and setup Playwright
RUN python3 -m pip install playwright && \
    playwright install && \
    playwright install-deps

# Set environment variables for browser-use
ENV PYTHONUNBUFFERED=1
ENV DISPLAY=:1.0
