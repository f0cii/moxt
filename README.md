<h4 align="center">
    <p>
        <b>English</b> |
        <a href="https://github.com/f0cii/moxt/blob/main/README_zh.md">简体中文</a>
    </p>
</h4>

# MOXT

A high-performance trading library, written in Mojo and C++, designed to simplify quantitative trading.

## Features

1. **Concise and Efficient Syntax**
   - **Mojo Programming Language**: Inspired by the ease of use of Python, the Mojo programming language has been designed with a concise and efficient syntax aimed at delivering performance comparable to that of C/C++/Rust, while maintaining code readability and ease of use.
   
2. **Integration with Multiple Exchanges**
   - **Broad Support**: Easily integrate with mainstream exchanges, such as OKX, Bybit, Binance, etc.
   
3. **Extensive Support for Technical Indicators**
   - **[TulipIndicators](https://tulipindicators.org/)**: Integrates over 104 technical indicators, offering powerful tools for market analysis and strategy development.
   
4. **Support for Multiple Strategies**
   - **Flexible Application**: Run and manage multiple trading strategies simultaneously, improving resource utilization and investment efficiency.
   
5. **Event-Driven Model**
   - **Efficient Response**: Optimize strategy execution and signal processing to ensure timely responses to market changes.
   
6. **Integration with [Photon](https://github.com/alibaba/PhotonLibOS) High-Performance Coroutine Library**
   - **Concurrent Processing**: Enhance the program's concurrency capabilities and optimize execution efficiency and resource utilization with the efficient Photon coroutine library.
   
7. **Low-Latency HTTP Client Component**
   - **Rapid Communication**: Ensure real-time and accurate data transmission and strategy execution with the low-latency HTTP client component.
   
8. **High-Performance WebSocket Module**
   - **Real-Time Data Stream**: Achieve real-time data exchange with exchanges and ensure immediate information updates and rapid strategy execution with the high-performance WebSocket module.
   
9. **Integration with [simdjson](https://github.com/simdjson/simdjson) Parsing Library**
   - **Efficient Parsing**: Utilize the simdjson parsing library for rapid JSON processing capabilities, ensuring efficient and accurate data parsing.

## System Requirements

To ensure optimal performance and compatibility, please make sure your system meets the following requirements:

- Operating System: Ubuntu 20.04+ (amd64)
- Python Environment: Python 3.9+ is required. It is recommended to manage it using [Miniconda](https://docs.anaconda.com/free/miniconda/index.html).
- Mojo Programming Language Version: 24.3.0

For information on how to install Mojo, please refer to the [Mojo Official Installation Guide](https://docs.modular.com/mojo/manual/get-started/). Make sure you are using the supported version of the operating system to avoid compatibility issues.

## Installation

Before starting, make sure you have installed the Mojo programming language and all necessary dependencies according to the system requirements. Next, you can install and configure this quantitative trading library by following the steps below:

1. Clone the Project

Clone this project into your local environment:

```bash
git clone https://github.com/f0cii/moxt.git
cd moxt
```

2. Use Docker (Optional)

If you prefer to use Docker to run the Mojo environment, you can use our provided Dockerfile by following these steps:

```bash
docker build -t moxt -f mojo.Dockerfile .
docker run -it moxt
```

This step is optional and is provided for those who wish to simplify their environment setup using Docker. If you are not familiar with Docker, we recommend checking the Docker Official Documentation for more information.

## Download libmoxt.so

Before running the application, you need to download the compiled libmoxt.so library file. You can use either curl or wget command to download it directly into your project directory:

```bash
# Install jq
sudo apt install jq
# Make the download script executable
chmod +x download_libmoxt.sh
# Run the download script
./download_libmoxt.sh
```

Note: These commands download the latest version of libmoxt.so from the moxt-cpp GitHub releases. Ensure you have curl or wget installed on your system to use these commands.

Alternatively, if you prefer to compile libmoxt.so yourself or need a specific version, please visit [moxt-cpp](https://github.com/f0cii/moxt-cpp) for compilation instructions.

## Why is it necessary to download libmoxt.so?

Some of the core functionalities of this project are implemented in C++ and compiled into the libmoxt.so shared library. This means that in order for the MOXT library to function correctly and take full advantage of these high-performance features, you need to download this shared library to your project directory. The C++ code for the project is located in the [moxt-cpp](https://github.com/f0cii/moxt-cpp) repository.

## Quick Start

```mojo
# Set script execution permissions
chmod +x ./scripts/ld
chmod +x ./scripts/mojoc
chmod +x ./build.sh

# Compile
./build.sh main.mojo -o moxt
# Set environment variables
source setup.sh
# Install Python dependencies
pip install tomli

# Running ./moxt initiates the quantitative trading process.
# Please note that the specific strategies to be run must be specified in the configuration file (config.toml). Ensure that the strategy settings in this file have been correctly configured according to your requirements before executing ./moxt.
./moxt
```

Note: The `trading_strategies` directory is used to store trading strategies.

## Community

Join our community to get help, share ideas, and collaborate!

* Discord: Join our [Discord server](https://discord.gg/XE8KJhq8) to chat with the MOXT community.

## About Me

Feel free to add me on WeChat for further discussions and sharing!

![WeChat QR Code](https://raw.githubusercontent.com/f0cii/moxt/main/assets/wechat.jpg)

## License

This project is licensed under the MIT License - see the [LICENSE] file for more details.

---

**Disclaimer: ** This project is for learning and research purposes only and does not constitute any trading or investment advice. Please use this project cautiously for actual trading.
