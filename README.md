# Zsh Development Environment Installer

专业的 Zsh 开发环境一键安装和管理工具，基于 Oh My Zsh 构建现代化、可扩展的终端环境。

## ✨ 特性

- 🚀 **一键安装** - 自动检测系统，安装所有依赖
- 📦 **组件化管理** - 声明式配置，新增插件只需修改一处
- 🔄 **增量更新** - 支持单独更新指定组件
- 📊 **状态查看** - 实时查看所有组件安装状态
- 🎨 **美观提示** - 彩色输出，清晰的日志级别
- 🔧 **高度可配置** - 支持跳过组件、预览模式等
- 🛡️ **安全可靠** - 幂等操作，自动备份，失败回滚

## 📋 系统要求

- **操作系统**: Ubuntu/Debian, Fedora, Arch/Manjaro, macOS
- **依赖**: bash 4.0+, curl, git, sudo
- **磁盘空间**: 至少 500MB

## 🚀 快速开始

### 一键安装（推荐）

```bash
# 执行安装脚本
bash -c "$(curl -fsSL https://raw.githubusercontent.com/aiimoyu/zsh_init/refs/heads/main/install.sh)"
```

### 自定义安装

```bash
# 预览安装过程（不实际执行）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/aiimoyu/zsh_init/refs/heads/main/install.sh)" -- --dry-run

# 跳过 Starship 安装
bash -c "$(curl -fsSL https://raw.githubusercontent.com/aiimoyu/zsh_init/refs/heads/main/install.sh)" -- --skip-starship

# 跳过所有插件安装
bash -c "$(curl -fsSL https://raw.githubusercontent.com/aiimoyu/zsh_init/refs/heads/main/install.sh)" -- --skip-plugins

# 详细日志输出
bash -c "$(curl -fsSL https://raw.githubusercontent.com/aiimoyu/zsh_init/refs/heads/main/install.sh)" -- --verbose

# 静默模式（仅显示错误）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/aiimoyu/zsh_init/refs/heads/main/install.sh)" -- --quiet
```

### 本地安装（可选）

```bash
# 克隆仓库
git clone https://github.com/aiimoyu/zsh_init.git
cd zsh_init

# 执行安装
./zsh_install.sh
```

## 📖 命令参考

### 安装命令

```bash
# 安装所有组件（默认）
./zsh_install.sh install

# 等价命令
./zsh_install.sh
```

### 更新命令

```bash
# 更新所有已安装的组件
./zsh_install.sh update

# 更新指定组件
./zsh_install.sh update zsh-syntax-highlighting

# 更新 Starship
./zsh_install.sh update starship
```

### 查询命令

```bash
# 查看所有组件状态
./zsh_install.sh status

# 列出所有可用组件
./zsh_install.sh list

# 查看帮助
./zsh_install.sh --help
```

## 📦 预置组件

### 核心框架

| 组件 | 类型 | 描述 |
|------|------|------|
| oh-my-zsh | git | Oh My Zsh 核心框架 |

### Zsh 插件

| 组件 | 描述 |
|------|------|
| zsh-syntax-highlighting | 命令语法高亮 |
| zsh-autosuggestions | Fish 风格的自动建议 |
| you-should-use | 别名使用提醒 |
| zsh-completions | 额外的自动补全 |

### 外部工具

| 组件 | 描述 |
|------|------|
| starship | 跨 shell 的美观提示符 |

### Oh My Zsh 内置插件

以下插件无需单独安装，已在 `.zshrc` 中配置：

- `git` - Git 别名和函数
- `z` - 目录跳转记忆
- `extract` - 一键解压
- `sudo` - 快速添加 sudo
- `command-not-found` - 命令缺失提示
- `safe-paste` - 安全粘贴
- `tmux` - Tmux 集成
- `history` - 历史搜索

## 🔧 添加新插件

### 步骤 1：在组件注册表中添加

编辑 `zsh_install.sh`，在 `COMPONENTS` 数组中添加（约第 64 行）：

```bash
declare -A COMPONENTS=(
    # ... 现有组件 ...
    
    # 添加新插件
    ["your-plugin"]="type:git|source:https://github.com/user/repo.git|path:$PLUGINS_DIR/your-plugin|desc:插件描述"
)
```

### 步骤 2：添加到默认插件列表

在 `DEFAULT_PLUGINS` 数组中添加（约第 78 行）：

```bash
readonly DEFAULT_PLUGINS=(
    "git"
    "z"
    # ... 其他插件 ...
    "your-plugin"  # 添加这里
)
```

### 完成！

无需修改其他代码，运行以下命令即可安装：

```bash
./zsh_install.sh install
```

## 📝 组件注册表格式

### Git 类型组件

```bash
["plugin-name"]="type:git|source:REPO_URL|path:INSTALL_PATH|desc:DESCRIPTION"
```

**字段说明**：
- `type:git` - 组件类型（Git 仓库）
- `source:URL` - Git 仓库地址
- `path:PATH` - 安装路径
- `desc:TEXT` - 组件描述

### Script 类型组件

```bash
["tool-name"]="type:script|source:SCRIPT_URL|check_cmd:COMMAND|desc:DESCRIPTION"
```

**字段说明**：
- `type:script` - 组件类型（安装脚本）
- `source:URL` - 安装脚本地址
- `check_cmd:CMD` - 用于检测是否安装的命令
- `desc:TEXT` - 组件描述

### 示例

```bash
# Git 类型示例
["zsh-autosuggestions"]="type:git|source:https://github.com/zsh-users/zsh-autosuggestions.git|path:$PLUGINS_DIR/zsh-autosuggestions|desc:Fish-like autosuggestions"

# Script 类型示例
["starship"]="type:script|source:https://starship.rs/install.sh|check_cmd:starship|desc:Cross-shell prompt"
```

## 🎯 使用示例

### 查看当前环境状态

```bash
$ ./zsh_install.sh status

Component Status:
NAME                      STATUS          VERSION
----                      ------          -------
oh-my-zsh                 installed       52d93f1
starship                  installed       starship 1.24.2
zsh-autosuggestions       installed       v0.7.0-12-gc3d4e57
zsh-syntax-highlighting   installed       0.8.0-2-ge0165ea
you-should-use            not installed   -
zsh-completions           not installed   -
```

### 更新特定插件

```bash
$ ./zsh_install.sh update zsh-syntax-highlighting

[INFO] Running pre-flight checks...
[INFO] Pre-flight checks passed
[INFO] Updating zsh-syntax-highlighting...
[INFO] Already up to date.
[INFO] Update completed!
```

### 预览安装过程

```bash
$ ./zsh_install.sh --dry-run install

[INFO] [DRY-RUN] Would run: sudo apt update && sudo apt install -y git curl zsh tmux
[INFO] [DRY-RUN] Would install zsh-syntax-highlighting (git) from https://...
[INFO] [DRY-RUN] Would update plugins in /home/user/.zshrc
```

## 🛠️ 故障排除

### 安装失败

1. **检查依赖**：确保已安装 `curl`, `git`, `sudo`
2. **检查网络**：确保可以访问 GitHub
3. **检查磁盘空间**：确保至少有 500MB 可用空间

```bash
# 查看详细日志
./zsh_install.sh --verbose install
```

### 插件加载失败

1. **检查插件路径**：确认插件已安装到正确目录
2. **检查 .zshrc 配置**：确认插件名已添加到 `plugins=()`
3. **重新加载配置**：

```bash
source ~/.zshrc
```

### 更新失败

```bash
# 手动更新特定插件
cd ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git pull
```

## 📂 项目结构

```
zsh_init/
├── zsh_install.sh      # 主安装脚本
├── README.md           # 项目文档
└── .gitignore         # Git 忽略文件
```

## 📥 下载脚本文件

如需下载脚本到本地，可使用以下命令：

```bash
# 下载 bootstrap 安装脚本
curl -fsSL https://raw.githubusercontent.com/aiimoyu/zsh_init/refs/heads/main/install.sh -o install.sh

# 添加执行权限
chmod +x install.sh

# 执行安装
./install.sh

# 或者下载主安装脚本
curl -fsSL https://raw.githubusercontent.com/aiimoyu/zsh_init/refs/heads/main/zsh_install.sh -o zsh_install.sh
chmod +x zsh_install.sh
./zsh_install.sh
```

## 🔐 安全说明

- 脚本会创建 `.zshrc` 备份（格式：`.zshrc.backup.YYYYMMDDHHMMSS`）
- 所有操作都是幂等的，可安全重复执行
- 使用 `--dry-run` 预览所有变更
- 远程脚本执行已最小化（仅 Starship 官方安装脚本）

## 📄 退出码

| 码值 | 含义 |
|------|------|
| 0 | 成功 |
| 1 | 通用错误 |
| 2 | 安装失败 |
| 3 | 不支持的操作系统 |
| 4 | 缺少依赖 |

## 🔗 相关链接

- **GitHub 仓库**: https://github.com/aiimoyu/zsh_init
- **提交 Issue**: https://github.com/aiimoyu/zsh_init/issues

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📝 更新日志

### v2.1.0

- ✨ 新增组件注册表架构，新增插件只需修改一处
- ✨ 新增 `update` 命令支持增量更新
- ✨ 新增 `status` 命令查看组件状态
- ✨ 新增 `list` 命令列出可用组件
- 🐛 修复变量未引用问题
- 🐛 修复颜色输出问题

### v2.0.0

- ✨ 重构为专业安装脚本
- ✨ 支持多 Linux 发行版
- ✨ 新增日志系统
- ✨ 新增 CLI 选项

## 👥 作者

aiimoyu
