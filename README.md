# BPLab Trace V7 — GitHub / Streamlit 运行包

本目录只包含程序运行所需文件。

## 部署

1. 将本目录内的全部文件上传到 GitHub 仓库根目录。
2. 在 Streamlit Community Cloud 中选择该仓库。
3. Main file path 填写 `app.py`。
4. 部署并打开 HTTPS 地址。

系统首次启动时会自动创建 SQLite 演示数据库，并初始化 82 条样品信息。

## 演示账号

- 管理员：`admin` / `admin123`
- 样品管理员：`receiver` / `receive123`
- 实验员：`tester` / `test123`
- 复核员：`reviewer` / `review123`
- 质量检测员：`quality` / `quality123`

本包用于流程演示。Streamlit Community Cloud 的本地文件可能因重启或重新部署而清空，正式系统应接入持久数据库和对象存储。
