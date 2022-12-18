#!/bin/bash
#
#*********************************
# author:         fibreyu
# version:        1.0
# date:           2022-12.17
# description:    create hard link of media files in a dir
# usage:          link.sh -s [source] -t [dest] -w -d --skip
#***********************************


set -e
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# 默认使用root用户运行
if [ $EUID -ne 0 ]; then
  echo "必须使用root用户运行" 2>&1
  exit 1
fi

# 源目录
SRC_DIR=""
# 目标目录
TARGET_DIR=""
# 当前工作目录
CUR_DIR=""
# 保持目录结构
KEEP_TREE=1
# 是否监听目录
WATCH=0
# 是否跳过创建，直接监听
SKIP=0
# 是否添加到自启动
INSTALL=0
# 删除自启动
UNINSTALL=0
# 后台运行
DAEMON=0
# 停止后台服务
KILL=0
# 配置文件目录
CONF_PATH="/etc/h_link"
# 默认脚本名称
HLINK="h_link.sh"
# 进程号
PID="PID"
# 存日志
LOG=0

# 获取参数
function Get_param() {
    [ $# -lt 1 ] && { Show_help; exit 0; }
    # 获取参数
    while [ $# -ge 1 ]; do
        case $1 in
            -s|--source)
                shift
                SRC_DIR=$1
                shift
                ;;
            -t|--target)
                shift
                TARGET_DIR=$1
                shift
                ;;
            -n|--nokeep)
                KEEP_TREE=0
                shift
                ;;
            -w|--watch)
                WATCH=1
                shift
                ;;
            -u|--uninstall)
                UNINSTALL=1
                shift
                ;;
            -d|--daemon)
                DAEMON=1
                shift
                ;;
            -i|--install)
                INSTALL=1
                shift
                ;;
            -k|--kill)
                KILL=1
                shift
                ;;
            --skip)
                SKIP=1
                shift
                ;;
            -l|--log)
                LOG=1
                shift
                ;;
            -h|--help)
                Show_help
                exit 0
                ;;
            *)
                echo "use -h or --help for help"
                exit 0
                ;;
        esac
    done
}

# 格式化目录参数
function Check_param() {
    [ ${KILL} -eq 1 ] && return
    local cur_dir="$(pwd)"
    local keep=""

    # 创建配置文件目录
    [ ! -d ${CONF_PATH} ] && mkdir -p ${CONF_PATH}
    # [ ! -d "${CONF_PATH}/history" ] && mkdir -p ${CONF_PATH}/history

    [ ${KEEP_TREE} -eq 1 ] && keep="yes" || keep="no"

    # 两个目录都空则直接退出
    [ -z "${TARGET_DIR}" ] && [ -z "${SRC_DIR}" ] && echo "must set source dir and target dir" && exit 1    
    # 目标目录为空则设置目标目录为当前目录
    [ -n "${SRC_DIR}" ] && [ -z "${TARGET_DIR}" ] && TARGET_DIR=${cur_dir}
    # 源目录为空则设置源目录为当前目录
    [ -n "${TARGET_DIR}" ] && [ -z "${SRC_DIR}" ] && SRC_DIR=${cur_dir}
    # 判断目录是否存在
    [ -d ${TARGET_DIR} ] || mkdir -p ${TARGET_DIR}
    [ -d ${SRC_DIR} ] || { echo "source path error"; exit 1; }

    # 获取绝对路径
    TARGET_DIR=$(cd ${TARGET_DIR};pwd)
    SRC_DIR=$(cd ${SRC_DIR};pwd)
    # 去除路径最后的 /
    TARGET_DIR=`echo ${TARGET_DIR} || sed "s|(\S*[^/])/*$|\1|"`
    SRC_DIR=`echo ${SRC_DIR} || sed "s|(\S*[^/])/*$|\1|"`

    printf "%s : \n" parameters 
    printf "%-10s : %s\n" "source dir" ${SRC_DIR}
    printf "%-10s : %s\n" "target dir" ${TARGET_DIR}
    printf "%s : %s\n" "keep dir structure" ${keep}
}

# 遍历目录
# $1 : 源目录
function Walk_dir() {
    # 绝对路径
    local cur_full_dir=$1
    # 去除前缀
    local cur_dir=${1#*$SRC_DIR}

    # 判断当前目录在目标位置是否存在,不存在则创建
    [ ${KEEP_TREE} -eq 1 ] && [ ! -d "${TARGET_DIR}${cur_dir}" ] && mkdir -p ${TARGET_DIR}${cur_dir}

    for file in `ls $1`; do
        if [ -d $1"/"$file ]; then
            echo "process directory: ${1}/${file}"
            Walk_dir ${1}"/"${file}
        else
            echo "process file : ${1}/${file}"
            Create_hard_link ${1}"/"${file} ${TARGET_DIR}${cur_dir}"/"${file}
        fi
    done
}

# 创建硬链接
# $1 src file
# $2 dest file
function Create_hard_link() {
    local src=$1
    local target=$2

    # 不维持目录结构，就采用目标目录
    [ ${KEEP_TREE} -eq 0 ] && target=${TARGET_DIR}

    # 判断源文件是否存在，不存在直接返回
    [ -f $src ] || { echo "$src not exists"; return; }
    # 不是同一硬链接则创建
    [ $src -ef $target ] || ln -f $src $target
} 


# 显示帮助
function Show_help() {
echo "args: -s dir -t dir [-n] [-k] [-w] [-i] [-l] [-u] [-d] [--skip]"
printf "\t%-15s %s\n" "-s|--source" "源目录"
printf "\t%-15s %s\n" "-t|--target" "目标目录"
printf "\t%-15s %s\n" "-n|--nokeep" "保持目录结构，默认保持，添加本参数取消保持"
printf "\t%-15s %s\n" "-w|--watch" "是否监听"
printf "\t%-15s %s\n" "-l|--log" "是否保存日志"
printf "\t%-15s %s\n" "-d|--daemon" "后台运行"
printf "\t%-15s %s\n" "-k|--kill" "停止后台运行"
printf "\t%-15s %s\n" "-i|--install" "开机自启动"
printf "\t%-15s %s\n" "-u|--uninstall" "禁止自启动"
printf "\t%-15s %s\n" "--skip" "跳过创建，直接开始监听"
printf "\t%-15s %s\n" "-h|--help" "显示帮助"

printf "样例：\n"
printf "\t%-15s %s\n" "保持原目录结构创建硬链接" "-s dir -t dir"
printf "\t%-15s %s\n" "不保持原目录结构创建硬链接" "-s dir -t dir -n"
printf "\t%-15s %s\n" "创建硬链接并记录日志" "-s dir -t dir"
printf "\t%-15s %s\n" "跳过创建，监听源目录的新文件" "-s dir -t dir -w --skip"
printf "\t%-15s %s\n" "在目标创建硬链接并监听" "-s dir -t dir -w --skip"
printf "\t%-15s %s\n" "后台运行" "-s dir -t dir -w -d"
printf "\t%-15s %s\n" "添加开机自启动" "-s dir -t dir -w -i"
printf "\t%-15s %s\n" "取消开机自启动" "-u"
printf "\t%-15s %s\n" "停止所有进程" "-k"
}

# 监听目录
function Watch_dir() {
    local watch_dir=$SRC_DIR
    local watch_log="${CONF_PATH}/watchlog"
    local watch_lock="${CONF_PATH}/watchlock"
    touch ${watch_lock}
    
    while true; do
        # 寻找比基准文件更新的文件
        find $watch_dir -newer ${watch_lock} -exec echo {} >> ${watch_log} \;
        # 删除第一行，即最顶层目录也就是源目录
        # 用sed删除，如果匹配字符串有/，可以使用:,分割
        # 如果使用|?则第一个字符需要转义 如 \| \?
        sed -i '\?^'"${watch_dir}"'$?d' ${watch_log}

        # 找到更新的文件
        if [ -s ${watch_log} ]; then
            # 更新基准文件
            touch ${watch_lock}
            # 创建硬链接
            # cat $watch_log

            # cat ${watch_log} | while read line
            # do
            # done

            while read -r line
            do

                if [ -d ${line} ]; then  # 如果是目录
                    echo "process directory: ${line}"
                    Walk_dir ${line}
                else                     # 如果是文件
                    echo "process file : ${line}"
                    # local base_name=${line##*/}
                    local cur_dir=${line#*$SRC_DIR}
                    Create_hard_link ${line} "${TARGET_DIR}${cur_dir}"
                fi
            done < ${watch_log}

            # 保存日志
            local stamp=`date "+%Y-%m-%d-%H-%M-%S"`
            # mv ${watch_log} "${CONF_PATH}/history/${stamp}"
            if [ ${LOG} -eq 1 ]; then
                for ff in `cat ${watch_log}`; do
                    echo "${stamp} : ${ff}" >> ${CONF_PATH}/history_log
                done
            fi
            rm -rf ${watch_log}
        fi

        # 解决死循环CPU占用率100%的问题
        sleep 1
    done
}

# 关闭所有相关进程
function Kill_proc() {
    local file_path="${CONF_PATH}/${HLINK}"
    local pid_path="${CONF_PATH}/${PID}"
    local filename=${0##*/}
    ps -ef | grep -E "${filename}|${HLINK}" | grep -v grep | grep -v $$ | awk '{print $1}' > ${pid_path}

    [ -f ${pid_path} ] && sed -i '/^$/d' ${pid_path}
    
    if [ -s ${pid_path} ]; then
        while read -r line
        do
            echo "kill process : ${line}"
            kill -9 ${line} 2> /dev/null
        done < ${pid_path}
    fi

    rm -rf ${pid_path}

    echo "已停止所有进程"
    exit 0
}

# 取消自启动
function Uninstall_service() {
    local file_path="${CONF_PATH}/${HLINK}"
    # 删除定时任务
    if [ -f /etc/crontab ]; then
        sed -i '/'"${HLINK}"'/d' /etc/crontab
    elif [ -d /etc/crontabs ]; then
        sed -i '/'"${HLINK}"'/d' /etc/crontabs/root
    else
        echo "当前系统无开机自启动"
    fi
    echo "已取消自启动"
    # 删除文件
    [ -f ${file_path} ] && rm -rf ${file_path}
    exit 0
}

# 安装服务，开机启动
function Install_service() {
    local file_path="${CONF_PATH}/${HLINK}"
    # 添加启动文件
    [ ! -f ${file_path} ] && cp -a $0 ${file_path} && chmod a+x ${file_path}

    # 准备命令
    args=`echo $* | sed 's/( -d)|( --daemon)//g'`
    # local command="flock -x -w 3 ${CONF_PATH}/process.lock -c \"nohup ${file_path} $args 2>&1 &\""
    local command="flock -xn ${CONF_PATH}/process.lock -c \"nohup ${file_path} $args >>/dev/null 2>&1 &\""
    # 每小时执行一次，单实例
    local line=""
    # 添加任务
    local line="0 */1 * * * root ${command}"
    if [ -f /etc/crontab ]; then
        line="0 */1 * * * root ${command}"
        echo ${line} >> /etc/crontab
        echo "@reboot root ${command}"
    elif [ -d /etc/crontabs ]; then
        local line="0\t*/1\t*\t*\t*\t${command}"
        echo -e ${line} >> /etc/crontabs/root
        echo -e "@reboot\t${command}" >> /etc/crontabs/root
    else
        echo "当前系统无法创建开机自启动"
    fi
    echo "已添加开机自启动"
    exit 0
}

# 创建守护进程
function Create_daemon() {
    [ ! -d ${CONF_PATH} ] && mkdir -p ${CONF_PATH}
    local file_path="${CONF_PATH}/${HLINK}"
    # 添加文件
    [ ! -f ${file_path} ] && cp -a $0 ${file_path} && chmod a+x ${file_path}
    # 准备命令
    local args=`echo $* | sed 's/( -d)|( --daemon)//g'`
    local command="flock -xn ${CONF_PATH}/process.lock -c \"nohup bash ${file_path} $args 2>&1 &\""
    cd ${CONF_PATH}
    eval ${command}
    # 保存pid
    # echo $! >> "${CONF_PATH}/${PID}"
    echo "启动成功"
    exit 0
}

# 生成参数
function Generate_args() {
    local cur_args=""
    [ -n ${SRC_DIR} ] && cur_args="${cur_args} -s ${SRC_DIR} "
    [ -n ${TARGET_DIR} ] && cur_args="${cur_args} -t ${TARGET_DIR} "
    [ ${KEEP_TREE} -eq 0 ] && cur_args="${cur_args} -n "
    [ ${WATCH} -eq 1 ] && cur_args="${cur_args} -w "
    [ ${SKIP} -eq 1 ] && cur_args="${cur_args} --skip "
    [ ${LOG} -eq 1 ] && cur_args="${cur_args} -l"
    echo ${cur_args}
}

# 准备配置目录
function Prepare_conf_path() {
    [ -d ${CONF_PATH} ] || mkdir -p ${CONF_PATH}
    [ -f "${CONF_PATH}/process.lock" ] || touch "${CONF_PATH}/process.lock"
}

# 主函数
function Main() {
    # 获取参数
    Get_param $@
    # 准备目录
    Prepare_conf_path
    # 关闭所有进程选项
    [ ${KILL} -eq 1 ] && Kill_proc
    # 取消自启动
    [ ${UNINSTALL} -eq 1 ] && Uninstall_service
    # 检查参数
    Check_param
    # 后台运行
    [ ${DAEMON} -eq 1 ] && Create_daemon `Generate_args`
    # 添加crontab自启动
    [ ${INSTALL} -eq 1 ] && Install_service `Generate_args`
    # 遍历目录
    [ $SKIP -eq 0 ] && Walk_dir $SRC_DIR $TARGET_DIR
    # 监听目录
    [ $WATCH -eq 1 ] && Watch_dir 
    
    
}

Main $@