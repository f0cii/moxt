# MOXT

一个高性能的交易库，用Mojo和C++编写，旨在简化量化交易。

## 特点

1. **简洁高效的语法**
   - **Mojo编程语言**：受Python易用性的启发，Mojo设计了简洁且高效的语法，旨在提供类似C/C++/Rust的高性能，同时保持代码的可读性和易用性。
   
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

## 系统要求

为了确保最佳性能和兼容性，请确保您的系统满足以下要求：

- 操作系统：Ubuntu 20.04+ (amd64)
- Python环境：Python 3.9+，推荐使用[Miniconda](https://docs.anaconda.com/free/miniconda/index.html)进行管理
- Mojo编程语言版本：24.3.0

关于如何安装Mojo，请参考[Mojo官方安装指南](https://docs.modular.com/mojo/manual/get-started/)。确保您使用的是支持的操作系统版本，以避免兼容性问题。

## 安装

在开始之前，请确保您已按照系统要求安装了Mojo编程语言和所有必要的依赖项。接下来，您可以通过以下步骤安装和配置本量化交易库：

1. 克隆项目

克隆本项目到您的本地环境：

```bash
git clone https://github.com/f0cii/moxt.git
cd moxt
```

2. 使用Docker（可选）

如果您偏好使用Docker来运行Mojo环境，可以通过以下步骤使用我们提供的Dockerfile：

```bash
docker build -t moxt -f mojo.Dockerfile .
docker run -it moxt
```

这一步是可选的，为那些希望通过Docker简化环境配置的用户提供便利。如果您不熟悉Docker，建议查看Docker官方文档以获取更多信息。

## 下载 libmoxt.so

在运行应用程序之前，您需要下载编译好的 libmoxt.so 库文件。您可以使用 curl 或 wget 命令直接将其下载到您的项目目录中：

```bash
# 安装 jq
sudo apt install jq
# 将下载脚本设置为可执行
chmod +x download_libmoxt.sh
# 运行下载脚本
./download_libmoxt.sh
```

注意：这些命令从 moxt-cpp GitHub 发布中下载 libmoxt.so 的最新版本。确保您的系统中已安装 curl 或 wget 以使用这些命令。

或者，如果您更倾向于自己编译 libmoxt.so 或需要特定版本，请访问 [moxt-cpp](https://github.com/f0cii/moxt-cpp) 获取编译指南。

## 为什么需要下载libmoxt.so？

本项目的一些核心功能是基于C++实现的，并被编译为libmoxt.so共享库。这意味着，为了确保MOXT库能够正常运行并充分利用这些高性能特性，您需要将此共享库下载到您的项目目录中。项目的C++代码位于[moxt-cpp](https://github.com/f0cii/moxt-cpp)仓库中。

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

# 运行 ./moxt 将启动量化交易过程。
# 请注意，运行的具体策略需要在配置文件（config.toml）中进行指定。确保在执行 ./moxt 之前，已根据您的需求正确配置了该文件中的策略设置。
./moxt
```

注意：`trading_strategies`目录用于存放交易策略。

## 授权

本项目采用 MIT 授权许可 - 请查看 [LICENSE] 文件了解更多细节。

## 社区

加入我们的社区，获取帮助，分享想法，进行协作！

* Discord：加入我们的[Discord服务器](https://discord.gg/XE8KJhq8)，与MOXT社区交流。

## 关于我

欢迎通过微信加我为好友，一起交流分享！

![WeChat QR Code](https://raw.githubusercontent.com/f0cii/moxt/main/assets/wechat.jpg)

---

**免责声明：** 本项目仅供学习和研究使用，不构成任何交易建议或投资建议。请谨慎使用该项目进行实际交易。
