# MOXT: 开源量化交易库

**MOXT**是一款领先的开源量化交易库，专为提高量化交易效率和效果而设计。它不仅具备简洁高效的语法、多交易所集成、丰富的技术指标支持，还提供高性能的协程支持、低延迟的HTTP客户端组件以及高效的WebSocket模块。特别是，MOXT集成了[Photon](https://github.com/alibaba/PhotonLibOS)协程库和[simdjson](https://github.com/simdjson/simdjson)解析库，确保了数据处理的极致性能，使得MoXT成为量化交易者的理想选择。

编译 libmoxt.so，请移步 [moxt-cpp](https://github.com/f0cii/moxt-cpp)

注意: 编译后，请将编译后的 libmoxt.so 文件拷贝到本项目目录

## 特点

1. **简洁高效的语法**
   - **Mojo语法**：借鉴Python的易用性，同时提供相当于C/C++/Rust的高性能。
   
2. **多交易所集成**
   - **广泛支持**：轻松集成主流交易所，如OKX、Bybit、Binance等。
   
3. **丰富的技术指标支持**
   - **[TulipIndicators](https://tulipindicators.org/)**：集成超过104种技术指标，为市场分析和策略开发提供强大工具。
   
4. **多策略支持**
   - **灵活运用**：同时运行和管理多个交易策略，提高资源利用率和投资效率。
   
5. **事件驱动模型**
   - **高效响应**：优化策略执行和信号处理，确保及时响应市场变化。
   
6. **集成[Photon](https://github.com/alibaba/PhotonLibOS)高性能协程库**
   - **并发处理**：通过高效的Photon协程库，提高程序的并发处理能力，优化执行效率和资源利用。
   
7. **低延迟HTTP客户端组件**
   - **快速通讯**：通过低延迟的HTTP客户端组件，确保数据传输和策略执行的实时性和准确性。
   
8. **高性能WebSocket模块**
   - **实时数据流**：利用高性能的WebSocket模块，实现与交易所的实时数据交流，保证信息的即时更新和策略的迅速执行。
   
9. **集成[simdjson](https://github.com/simdjson/simdjson)解析库**
   - **高效解析**：利用simdjson解析库，提供极速的JSON处理能力，确保数据解析的高效性和准确性。

## 简介

**MoXT**致力于成为最具影响力的开源量化交易库之一，为量化交易人员提供一个强大、灵活且易于使用的平台。它适合各类用户，从量化交易新手到专业交易者，都能在MOXT中找到所需工具，以应对复杂多变的市场环境。

## 安装

确保你的环境中已经安装了 Mojo 编程语言(v0.7.0)。在项目目录下运行以下命令安装依赖：

```bash
请参考mojo官方文档安装

或者使用mojo容器
docker build -t mojo -f mojo.Dockerfile .
docker run -it mojo
```

## 快速开始

```mojo
# 设置脚本可执行权限
chmod +x ./scripts/ld
chmod +x ./scripts/mojoc
chmod +x ./build.sh

# 编译
./build.sh main.mojo -o moxt
# 设置环境变量
source setup.sh
# 安装python依赖库
pip install tomli
# 运行
./moxt

# 示例策略目录
trading_strategies

```

## 授权

本项目采用 MIT 授权许可 - 请查看 [LICENSE] 文件了解更多细节。

---

**免责声明：** 本项目仅供学习和研究使用，不构成任何交易建议或投资建议。请谨慎使用该项目进行实际交易。
