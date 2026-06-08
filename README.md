# Qingqi Claude Code Bootstrap

这是青契团队给新队友用的公开安装器。

主仓库 `hhh-dahah/qingqi` 是 private 私有仓库，所以不能直接用 `raw.githubusercontent.com/hhh-dahah/qingqi/...` 下载脚本，否则会看到 `404 Not Found`。

这个公开仓库只放一个薄安装器：

- 先检查或安装 GitHub CLI `gh`。
- 引导队友登录 GitHub。
- 登录后从私有主仓库读取真正的 `scripts/claude-code-bootstrap.ps1`。
- 执行主仓库里的安装脚本。

不放任何 `.env`、API Key、token、MongoDB 连接串、CloudBase 密钥或个人登录态。

## 一行命令

在 Windows PowerShell 里运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/hhh-dahah/qingqi-claude-bootstrap/main/install.ps1 | iex"
```

## 在哪里运行

任意盘、任意文件夹都可以。你可以从 Windows 开始菜单打开普通 PowerShell，直接粘贴命令运行。

不用先创建 `D:\桌面\第一版mvp-dev`，不用先进入项目目录。真正的主脚本会自动创建或更新青契项目目录。

## 需要什么权限

队友的 GitHub 账号必须能访问私有仓库：

```text
hhh-dahah/qingqi
```

如果没有权限，安装器会在拉取私有脚本时失败。解决方式是让仓库管理员把队友加入 GitHub 仓库协作者。

## 安装后

默认情况下，青契项目会在：

```powershell
D:\桌面\第一版mvp-dev
```

日常开发进入项目：

```powershell
cd D:\桌面\第一版mvp-dev
claude
```

## 安全说明

这个公开安装器不保存、不读取、不输出密钥。登录 GitHub 是为了证明你有访问私有青契仓库的权限。