# moxt

moxt 是一个基于 Mojo 编程语言的量化交易库，旨在提供简单而灵活的工具，以便开发者能够快速创建和测试量化交易策略。

编译 libmoxt.so，请移步 [moxt-cpp](https://github.com/f0cii/moxt-cpp)

注意: 编译后，请将编译后的 libmoxt.so 文件拷贝到本项目目录

## 特性

- 支持多种交易所：（okx,bybit,...）
- 提供简洁的 API 接口，方便集成和使用
- ...

## 安装

确保你的环境中已经安装了 Mojo 编程语言(v0.6.1)。在项目目录下运行以下命令安装依赖：

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
# 运行
./moxt

# 创建交易实例

# 获取市场行情

# 实现你的交易策略...
```

## 授权

本项目采用 MIT 授权许可 - 请查看 [LICENSE] 文件了解更多细节。

---

**免责声明：** 本项目仅供学习和研究使用，不构成任何交易建议或投资建议。请谨慎使用该项目进行实际交易。
