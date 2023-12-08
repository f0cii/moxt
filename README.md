# moxt

moxt 是一个基于 Mojo 编程语言的量化交易库，旨在提供简单而灵活的工具，以便开发者能够快速创建和测试量化交易策略。

编译 libmoxt.so，请移步 [moxt-cpp](https://github.com/f0cii/moxt-cpp)

## 特性

- 支持多种交易所：（okx,bybit,...）
- 提供简洁的 API 接口，方便集成和使用
- ...

## 安装

确保你的环境中已经安装了 Mojo 编程语言(v0.6.0)。在项目目录下运行以下命令安装依赖：

```bash
其他步骤省略，请参考官方文档
modular install mojo
```

## 快速开始

```mojo
# 设置脚本可执行权限
chmod +x ./scripts/ld
chmod +x ./scripts/mojoc
chmod +x ./moxt_test.sh

# 运行示例项目
./moxt_test.sh

# 创建交易实例

# 获取市场行情

# 实现你的交易策略...
```

## 文档

详细的文档和 API 参考请参阅 [文档链接]。

## 贡献

欢迎贡献代码、报告问题或提出改进建议。请查看 [贡献指南] 了解更多信息。

## 授权

本项目采用 MIT 授权许可 - 请查看 [LICENSE] 文件了解更多细节。

---

**免责声明：** 本项目仅供学习和研究使用，不构成任何交易建议或投资建议。请谨慎使用该项目进行实际交易。

[文档链接]: #  # TODO: 添加文档链接
[贡献指南]: CONTRIBUTING.md # TODO: 创建贡献指南文件
[LICENSE]: LICENSE