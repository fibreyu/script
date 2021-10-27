#!/bin/bash
#
#*********************************
# author:         fibreyu
# version:        1.0
# date:           2021-10.19
# description:    create soft link of media files in a dir
# usage:          slink.sh [source] [dest]
#***********************************



# 文件格式
SUFFIX=(.mkv .avi .mp4 .rmvb .iso .mp3 .wav .ape .flac)

# 源目目录
SRC_PATH=$(realpath ${1})
# 目的目录
DEST_PATH=$(realpath ${2})

# 处理
function StartProcess() {
  echo "process $1"
  for item in "$1"/*; do
    # 文件全路径包括文件名
    local full_file_path=$(realpath "${item}")
    # 文件路径不包括文件名
    local file_path=$(dirname "${full_file_path}")
    # 文件全名
    local file_name=$(basename "${full_file_path}")
    # 文件名去掉扩展
    local base_file_name=${file_name%.*}
    # 文件扩展名
    local ext_file_name=${file_name##*.}
    
    # 处理目录
    if [[ -d ${full_file_path} ]]; then
      # echo "process dir ${full_file_path}"
      StartProcess "$full_file_path"
      # 目录处理完继续下一个文件，不继续往下运行当前文件
      continue;
    fi
    
    # 目标文件存在，且是软连接
    # echo ${DEST_PATH}/${file_name}
    # echo ${DEST_PATH}/${file_name}
    # echo "----------${DEST_PATH}/${file_name}"
    if [[ -e "${DEST_PATH}/${file_name}" && -L "${DEST_PATH}/${file_name}" ]]; then
      # 目标文件的链接路径是该文件
      # echo "$(readlink ${DEST_PATH}/${file_name})--aaa"
      # echo "${full_file_path}"
      if [[ $(readlink "${DEST_PATH}/${file_name}") == "${full_file_path}" ]]; then
        echo "already exists soft link file: ${DEST_PATH}/${file_name}"
        continue;
      fi
    fi

    # 处理文件，做硬链接
    if [[ -f ${full_file_path} ]]; then
      # echo "process file ${full_file_path}"
      if [[ "${SUFFIX[@]}" =~ ${ext_file_name} ]]; then
        echo "create soft link -> ${DEST_PATH}/${file_name}"
        ln -sf "${full_file_path}" "${DEST_PATH}/${file_name}"
      fi
    fi
  done
}

# 初始化
function Start() {

  # 判断源路径是否存在
  if [[ ! -e ${SRC_PATH} ]]; then
    echo "dir: ${SRC_PATH}  is not exists"
    echo "exit"
    exit -1
  fi

  # 源路径不是目录则退出
  if [[ ! -d ${SRC_PATH} ]]; then
    echo "${SRC_PATH} is not dir"
    echo "exit"
    exit -1
  fi

  # 目标路径存在且不是目录
  if [[ -e ${DEST_PATH} && ! -d ${DEST_PATH} ]]; then
    echo "${DEST_PATH} is not dir or not exits"
    echo "exit"
    exit -1
  fi

  # 目标目录不存在则创建目录
  if [[ ! -d ${DEST_PATH} ]];then
    echo "create dir: ${DEST_PATH}"
    mkdir ${DEST_PATH}
    chmod 777 ${DEST_PATH}
  fi

  # 执行操作
  StartProcess $SRC_PATH $DEST_PATH
}

Start
