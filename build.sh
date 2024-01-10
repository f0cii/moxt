#!/bin/bash

# 定义默认输出文件名变量
output="" 

# 解析输入参数
while [[ $# -gt 0 ]]; do
  case $1 in
    -o)
      # 获取输出文件名参数
      output="$2"
      shift 2
      ;;
    *)
      # 获取输入mojo文件名
      input="$1" 
      shift
      ;;
  esac
done

# 如果没有指定输出文件名,默认设置为输入文件名
if [ -z "$output" ]; then
  output="${input%.*}"
fi

# 构造mojoc命令
cmd="./scripts/mojoc $input -lmoxt -L . -o $output"

# 打印将要执行的命令
echo "Executing command: $cmd"

# 执行命令 
$cmd

# 检查返回状态
if [ $? -eq 0 ]; then
  echo "Command executed successfully"
else
  echo "Command execution failed" 
fi