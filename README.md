<h4 align="center">
    <p>
        <b>English</b> |
        <a href="https://github.com/f0cii/moxt/blob/main/README_zh.md">简体中文</a>
    </p>
</h4>

# MOXT

A high-performance trading library, written in Mojo and C++, designed to simplify quantitative trading.

## Features

1. **Simple and Efficient Syntax**
   - **Mojo Syntax**: Borrowing the usability of Python while providing the high performance of C/C++/Rust.
   
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

## Installation

Ensure Mojo programming language (v0.7.0) is installed in your environment. Run the following commands in the project directory to install dependencies:

```bash
Refer to the official mojo documentation for installation

Or use the mojo docker
docker build -t mojo -f mojo.Dockerfile .
docker run -it mojo
```

## Downloading libmoxt.so

Before running the application, you need to download the compiled libmoxt.so library file. You can use either curl or wget command to download it directly into your project directory:

```bash
# Install jq
sudo apt  install jq
# Make the download script executable
chmod +x download_libmoxt.sh
# Run the download script
./download_libmoxt.sh
```

Note: These commands download the latest version of libmoxt.so from the moxt-cpp GitHub releases. Ensure you have curl or wget installed on your system to use these commands.

Alternatively, if you prefer to compile libmoxt.so yourself or need a specific version, please visit [moxt-cpp](https://github.com/f0cii/moxt-cpp) for compilation instructions.

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
# Run
./moxt

# Example strategy directory
trading_strategies

```

## Community

Join our community to get help, share ideas, and collaborate!

* Discord: Join our [Discord server](https://discord.gg/XE8KJhq8) to chat with the MOXT community.
* QQ Group: Connect with us on QQ Group (717747352) for discussions in Chinese.

## License

This project is licensed under the MIT License - see the [LICENSE] file for more details.

---

**Disclaimer: ** This project is for learning and research purposes only and does not constitute any trading or investment advice. Please use this project cautiously for actual trading.
