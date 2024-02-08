<h4 align="center">
    <p>
        <b>English</b> |
        <a href="https://github.com/f0cii/moxt/blob/main/README_zh.md">简体中文</a>
    </p>
</h4>

# MOXT: Open Source Quantitative Trading Library

**MOXT** is a leading open-source quantitative trading library designed to enhance the efficiency and effectiveness of quantitative trading. It features a simple and efficient syntax, integration with multiple exchanges, extensive support for technical indicators, and provides high-performance coroutine support, low-latency HTTP client components, and an efficient WebSocket module. Notably, MOXT integrates the [Photon](https://github.com/alibaba/PhotonLibOS) coroutine library and the [simdjson](https://github.com/simdjson/simdjson) parsing library, ensuring ultimate performance in data processing, making MOXT an ideal choice for quantitative traders.

To compile libmoxt.so, please visit [moxt-cpp](https://github.com/f0cii/moxt-cpp)

Note: After compiling, please copy the compiled libmoxt.so file to this project directory.

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

## License

This project is licensed under the MIT License - see the [LICENSE] file for more details.

---

**Disclaimer: ** This project is for learning and research purposes only and does not constitute any trading or investment advice. Please use this project cautiously for actual trading.
