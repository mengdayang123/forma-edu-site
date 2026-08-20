# GitHub Pages 免费发布

当前电脑已检测到 GitHub CLI 登录状态，但本文件不会自动创建公开仓库或上传代码。

确认品牌名和仓库名后，可以在项目目录执行：

```bash
gh repo create <repository-name> --public --source=. --remote=origin --push
gh workflow run "Deploy static site to GitHub Pages" --repo "<github-user>/<repository-name>"
```

仓库的 `Settings → Pages` 选择 `GitHub Actions`。工作流完成后，GitHub 会显示类似：

`https://<github-user>.github.io/<repository-name>/`

GitHub Pages 适合当前纯静态站。D1 后台函数仍应部署到 Cloudflare Pages/Workers，不能仅靠 GitHub Pages 执行。

