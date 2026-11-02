#!/bin/bash
# ai-goofish-monitor 服务管理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PID_FILE="$SCRIPT_DIR/logs/app.pid"
LOG_FILE="$SCRIPT_DIR/logs/app.log"
mkdir -p "$SCRIPT_DIR/logs"

get_pid() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "$pid"
            return
        fi
    fi
    # 备用方案：查找正在运行的 src.app 进程
    local pids
    pids=$(pgrep -f "src.app" || true)
    if [ -n "$pids" ]; then
        echo "$pids" | head -n 1
        return
    fi
    echo ""
}

start() {
    local pid
    pid=$(get_pid)
    if [ -n "$pid" ]; then
        echo "服务已在运行中 (PID: $pid)"
        echo "Web 访问地址: http://localhost:8000"
        return
    fi

    echo "正在启动 ai-goofish-monitor..."
    if [ -d "$SCRIPT_DIR/.venv" ]; then
        source "$SCRIPT_DIR/.venv/bin/activate"
    fi

    nohup python3 -m src.app > "$LOG_FILE" 2>&1 &
    local new_pid=$!
    echo "$new_pid" > "$PID_FILE"

    sleep 2
    if ps -p "$new_pid" > /dev/null 2>&1; then
        echo "✓ 服务启动成功 (PID: $new_pid)"
        echo "Web 管理后台: http://localhost:8000"
        echo "默认账号密码: admin / admin123"
        echo "日志文件: $LOG_FILE"
    else
        echo "✗ 服务启动失败，请查看日志: $LOG_FILE"
        exit 1
    fi
}

stop() {
    local pid
    pid=$(get_pid)
    if [ -z "$pid" ]; then
        echo "服务未在运行"
        rm -f "$PID_FILE"
        return
    fi

    echo "正在停止服务 (PID: $pid)..."
    kill "$pid" 2>/dev/null || true
    sleep 2
    if ps -p "$pid" > /dev/null 2>&1; then
        echo "尝试强制终止..."
        kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
    echo "✓ 服务已停止"
}

status() {
    local pid
    pid=$(get_pid)
    if [ -n "$pid" ]; then
        echo "✓ 服务运行中 (PID: $pid)"
        echo "访问地址: http://localhost:8000"
        echo "健康状态:"
        curl -s http://127.0.0.1:8000/health || echo " (无法访问)"
        echo ""
    else
        echo "✗ 服务未运行"
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 1
        start
        ;;
    status)
        status
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
