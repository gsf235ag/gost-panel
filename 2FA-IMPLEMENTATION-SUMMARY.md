# GOST Panel 2FA (TOTP) 双因素认证实现总结

## 已完成的后端实现

### 1. 依赖安装
✅ 已安装 `github.com/pquerna/otp` 和 `github.com/pquerna/otp/totp`

### 2. 数据模型 (internal/model/model.go)
✅ 在 User struct 中添加了以下字段:
```go
TwoFactorEnabled bool   `gorm:"default:false" json:"two_factor_enabled"`
TwoFactorSecret  string `gorm:"size:100" json:"-"`
BackupCodes      string `gorm:"type:text" json:"-"` // JSON array of hashed codes
```

### 3. TOTP 服务 (internal/service/totp.go)
✅ 创建了完整的 TOTP 服务，包含:
- `GenerateTOTPSecret(username)` - 生成密钥和二维码
- `ValidateTOTP(secret, code)` - 验证 TOTP 代码
- `GenerateBackupCodes()` - 生成 8 个备份码
- `ValidateBackupCode(storedHashesJSON, code)` - 验证并使用备份码

### 4. API Handlers (internal/api/)
✅ 创建了 2fa_handlers.go 包含:
- `login2FA(c)` - 处理 2FA 验证登录

✅ 在 handlers.go 中添加:
- `enable2FA(c)` - 开始启用 2FA（生成密钥和二维码）
- `verify2FA(c)` - 验证并正式启用 2FA（生成备份码）
- `disable2FA(c)` - 禁用 2FA（需要密码验证）

### 5. 登录流程修改 (internal/api/server.go)
✅ 修改了 `login(c)` 函数:
- 检测用户是否启用 2FA
- 如果启用，返回 `requires_2fa: true` 和 5分钟有效的临时令牌
- 否则正常返回 JWT token

### 6. 路由注册 (internal/api/server.go)
✅ 添加了以下路由:
```go
// 公开路由
api.POST("/login/2fa", s.login2FA)

// 认证路由
auth.POST("/profile/2fa/enable", s.enable2FA)
auth.POST("/profile/2fa/verify", s.verify2FA)
auth.POST("/profile/2fa/disable", s.disable2FA)
```

## 已完成的前端实现

### 7. API 接口 (web/src/api/index.ts)
✅ 添加了以下 API 函数:
```typescript
export const enable2FA = () => api.post('/profile/2fa/enable')
export const verify2FA = (code: string) => api.post('/profile/2fa/verify', { code })
export const disable2FA = (password: string) => api.post('/profile/2fa/disable', { password })
export const login2FA = (temp_token: string, code: string) => axios.post('/api/login/2fa', { temp_token, code })
```

### 8. 登录页面 (web/src/views/Login.vue)
✅ 修改了 Login.vue:
- 添加了 2FA 验证码输入表单
- 实现了两步登录流程:
  1. 用户名/密码登录 → 如果返回 `requires_2fa`，显示验证码输入框
  2. 输入 6 位数字验证码 → 调用 `login2FA` API
- 支持验证器 APP 生成的 TOTP 代码和备份码

### 9. 用户 Store (web/src/stores/user.ts)
✅ 修改了 login 函数:
- 检测并返回 2FA 响应
- 由 Login.vue 组件处理后续的 2FA 流程

### 10. 账户设置界面
⚠️ 部分完成 - 提供了实现代码文件，需要手动集成到 Layout.vue:
- `/root/gost-panel/web/src/views/Layout-2FA-addition.txt` - 包含所需的 JavaScript 函数
- `/root/gost-panel/web/src/views/Layout-2FA-template.txt` - 包含 Vue 模板代码

## 功能特性

### 启用 2FA 流程:
1. 用户在账户设置中点击"启用 2FA"
2. 后端生成 TOTP 密钥和二维码
3. 用户使用验证器 APP 扫描二维码或手动输入密钥
4. 用户输入验证器生成的 6 位代码进行验证
5. 验证成功后，系统生成 8 个备份码供用户保存
6. 2FA 正式启用

### 登录流程（启用 2FA 后）:
1. 输入用户名和密码
2. 密码验证成功后，显示 2FA 验证码输入框
3. 输入验证器生成的 6 位代码或备份码
4. 验证成功后完成登录

### 禁用 2FA 流程:
1. 用户在账户设置中点击"禁用 2FA"
2. 输入当前密码进行确认
3. 2FA 功能被禁用

### 安全特性:
- TOTP 密钥使用 HMAC-SHA1 算法，符合 RFC 6238 标准
- 备份码经过 SHA256 哈希后存储
- 备份码使用后自动失效（从列表中移除）
- 登录时的临时令牌仅 5 分钟有效
- 所有 2FA 操作记录操作日志
- 禁用 2FA 需要密码验证

## 待完成事项

### 前端集成:
1. 将 `Layout-2FA-addition.txt` 中的代码添加到 `web/src/views/Layout.vue` 的 `<script setup>` 部分
2. 将 `Layout-2FA-template.txt` 中的模板替换 Layout.vue 中现有的账户设置模态框
3. 确保 Layout.vue 的 `loadProfile` 函数包含 `two_factor_enabled` 状态的加载

### 数据库迁移:
项目使用 GORM AutoMigrate，新字段会在下次启动时自动添加。无需手动运行迁移。

### 测试:
部署后需要测试以下功能:
1. 启用 2FA 流程
2. 使用 2FA 登录
3. 使用备份码登录
4. 禁用 2FA
5. 验证操作日志是否正确记录

## 文件清单

### 后端新建文件:
- `/root/gost-panel/internal/service/totp.go` - TOTP 服务实现
- `/root/gost-panel/internal/api/2fa_handlers.go` - 2FA 登录处理器

### 后端修改文件:
- `/root/gost-panel/internal/model/model.go` - 添加 User 2FA 字段
- `/root/gost-panel/internal/api/handlers.go` - 添加 2FA 管理接口
- `/root/gost-panel/internal/api/server.go` - 修改登录逻辑和添加路由

### 前端修改文件:
- `/root/gost-panel/web/src/api/index.ts` - 添加 2FA API 接口
- `/root/gost-panel/web/src/views/Login.vue` - 实现 2FA 登录流程
- `/root/gost-panel/web/src/stores/user.ts` - 修改登录逻辑

### 前端待集成文件:
- `/root/gost-panel/web/src/views/Layout-2FA-addition.txt` - 账户设置脚本代码
- `/root/gost-panel/web/src/views/Layout-2FA-template.txt` - 账户设置模板代码

## 部署说明

根据 MEMORY.md 中的规则:
1. **不要本地编译** - VPS 资源不足
2. Push 代码到 main 分支
3. 等待 GitHub Actions 自动构建
4. 从 Actions Artifacts 下载编译好的 gost-panel
5. 使用以下命令部署:
```bash
systemctl stop gost-panel
cp gost-panel /opt/gost-panel/
systemctl start gost-panel
```

## 兼容的验证器 APP

推荐使用以下任意一款:
- Google Authenticator (iOS/Android)
- Microsoft Authenticator (iOS/Android)
- Authy (iOS/Android)
- 1Password
- LastPass Authenticator
- FreeOTP
