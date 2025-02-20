---
version: 1.0.0
status: Draft
last_updated: 2024-02-20

# WebSecurityConfig 安全配置漏洞报告

## 漏洞信息
- 漏洞ID: VULN-001
- 组件: WebSecurityConfig.java
- 风险等级: 高
- 影响范围: 全局安全配置

## CSRF 保护问题

### 1. CSRF 默认禁用
**问题描述**：
```java
@Value("${joychou.security.csrf.enabled}")
private Boolean csrfEnabled = false;
```
- CSRF 保护默认被禁用（csrfEnabled 默认值为 false）
- 这可能导致所有请求默认不进行 CSRF 校验

**影响**：
- 所有 POST/PUT/DELETE 等修改操作可能遭受 CSRF 攻击
- 攻击者可以诱导用户执行未授权的操作

**证据**：
```java
if (!csrfEnabled) {
    return false;  // 不进行 CSRF 校验
}
```

### 2. CSRF Token 配置不当
**问题描述**：
```java
.csrfTokenRepository(new CookieCsrfTokenRepository());
```
- CSRF Token 存储在 Cookie 中但未设置安全属性
- 没有启用 httpOnly 和 secure 标志

**建议修复**：
```java
.csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
.csrfTokenRepository(repo -> {
    repo.setCookieHttpOnly(true);
    repo.setCookieSecure(true);
});
```

## 认证配置问题

### 1. 密码存储不安全
**问题描述**：
```java
.inMemoryAuthentication()
.withUser("joychou").password("joychou123").roles("USER")
```
- 密码以明文形式存储在配置中
- 没有使用密码编码器（如 BCryptPasswordEncoder）
- 使用了内存认证，不适合生产环境

**建议修复**：
```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}

auth.userDetailsService(userDetailsService)
    .passwordEncoder(passwordEncoder());
```

## CORS 配置问题

### 1. 不安全的 CORS 配置
**问题描述**：
```java
allowOrigins.add("joychou.org");  // 没有指定协议
configuration.setAllowCredentials(true);
```
- 源列表中混合了 HTTP 和 HTTPS
- 允许凭证的同时配置了多个来源
- CORS 配置范围过于局限（仅限于 /cors/sec/httpCors）

**建议修复**：
- 统一使用 HTTPS
- 严格限制允许的源
- 扩大 CORS 配置范围到需要的接口

## 会话管理问题

### 1. 会话配置不完整
**问题描述**：
- 未配置会话超时时间
- 未启用会话固定保护
- Remember-Me 功能配置简单

**建议修复**：
```java
http.sessionManagement()
    .sessionFixation().changeSessionId()
    .maximumSessions(1)
    .expiredUrl("/login?expired");
```

## 整体建议

1. 安全配置加强：
   - 启用并正确配置 CSRF 保护
   - 实现适当的密码加密存储
   - 完善会话安全配置
   - 规范 CORS 策略

2. 生产环境建议：
   - 使用数据库存储用户信息
   - 实现完整的用户管理系统
   - 添加登录尝试限制
   - 实现完整的审计日志

3. 配置改进：
   - 将敏感配置移至配置文件
   - 添加适当的安全响应头
   - 完善错误处理机制
   - 规范化异常处理

## 风险评估
- 严重程度：高
- 利用难度：中
- 影响范围：全局
- 修复优先级：高

## 后续跟踪
- [ ] 验证 CSRF 保护是否已启用
- [ ] 确认密码存储已加密
- [ ] 检查 CORS 配置更新
- [ ] 验证会话安全加强 