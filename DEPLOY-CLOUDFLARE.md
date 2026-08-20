# 使用 Cloudflare Pages 免费发布

当前站点是纯静态文件，不需要传统服务器或数据库即可上线。发布后可使用免费的 `*.pages.dev` 地址，全球用户可通过 HTTPS 访问。

## 推荐方式：Direct Upload

1. 注册或登录 Cloudflare。
2. 打开 `Workers & Pages`，选择 `Create` → `Pages` → `Upload assets`。
3. 项目名建议使用 `forma-edu`，上传本目录中的 `index.html` 和 `assets/`。
4. 发布完成后，Cloudflare 会提供类似 `https://forma-edu.pages.dev` 的公开地址。

也可以使用 Cloudflare CLI：

```bash
npx wrangler login
npx wrangler pages project create forma-edu
npx wrangler pages deploy . --project-name forma-edu
```

这三个命令需要你自己的 Cloudflare 登录授权；命令执行后返回的 `pages.dev` 地址才是可验证的公网地址。

## 自定义域名

自定义域名通常需要付费购买。购买后在 Pages 项目的 `Custom domains` 中添加域名，Cloudflare 会自动配置 HTTPS。域名只负责地址，网站文件仍运行在 Cloudflare Pages。

## 当前表单行为

前端会优先请求 `/api/inquiry`。如果还没有绑定数据库，提交会自动回退为下载一份 `.txt` 询盘文件；绑定 D1 后，询盘会写入数据库。接口文件在 `functions/api/inquiry.js`，表结构在 `schema.sql`。

## 可选的免费后台：Cloudflare D1

1. 在 Cloudflare `Workers & Pages` 中创建 Pages 项目，项目名使用 `forma-edu-site`。
2. 在本地复制 `wrangler.toml.example` 为 `wrangler.toml`。
3. 执行 `npx wrangler d1 create forma-edu-inquiries`，把返回的 `database_id` 写入 `wrangler.toml`。
4. 执行 `npx wrangler d1 execute forma-edu-inquiries --remote --file=schema.sql`。
5. 在 Pages 项目的 Settings → Functions → D1 database bindings 中绑定 `DB`。
6. 在 Pages 项目的 Settings → Variables and Secrets 中设置：`ADMIN_PASSWORD`、`ADMIN_SECRET`。两者都选择 Secret，不要放在普通变量或代码中。
7. 执行 `npx wrangler pages deploy . --project-name forma-edu-site`，确保 `functions/`、`admin/` 和 `assets/` 一起发布。
8. 打开 `https://你的项目.pages.dev/admin/`，使用 `ADMIN_PASSWORD` 登录询盘后台。

后台文件：

- `admin/index.html`：管理员界面
- `functions/api/admin/login.js`：HttpOnly 登录会话
- `functions/api/admin/inquiries.js`：询盘列表和状态更新
- `functions/api/admin/session.js`：登录状态检查
- `schema.sql`：D1 表结构

不要把 D1 管理令牌或任何服务器密钥写进 `index.html`。正式收集前还应加入 Turnstile、隐私政策和数据保留规则。

截至 2026-08-20，官方文档列出的免费层包括 Pages 静态资源免费，Pages Functions 按 Workers Free 计划计量；D1 Free 计划列出每日 500 万行读取、10 万行写入和 5 GB 总存储。额度和计费规则可能变化，发布前应重新查看 [Pages Functions pricing](https://developers.cloudflare.com/pages/functions/pricing/) 与 [D1 pricing](https://developers.cloudflare.com/d1/platform/pricing/)。

## 发布前仍需替换

- `FORMA EDU` 是工作品牌名，正式品牌待确认。
- 最终联系方式、隐私政策、公司事实和可公开认证待补充。
- 任何规格和安全主张必须以最终型号文件为准。
