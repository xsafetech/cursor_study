---
version: 1.0.0
status: Draft
last_updated: 2024-02-20

# 登录控制器安全审计报告

## 漏洞信息
- 漏洞ID: VULN-004
- 组件: Login.java
- 风险等级: 高
- 影响范围: 认证功能

## 登录功能问题

### 1. 登录页面路由配置
**问题描述**：
```java
@RequestMapping("/login")
public String login() {
    return "login";
}
```
- 登录路由支持所有 HTTP 方法（GET、POST等）
- 没有防暴力破解机制
- 缺少登录失败处理
- 缺少登录尝试限制

**建议修复**：
```java
@Controller
public class Login {
    private static final int MAX_FAILED_ATTEMPTS = 5;
    private final LoginAttemptService loginAttemptService;
    
    @GetMapping("/login")
    public String loginPage() {
        return "login";
    }
    
    @PostMapping("/login")
    public String login(HttpServletRequest request) {
        String ip = request.getRemoteAddr();
        if (loginAttemptService.isBlocked(ip)) {
            return "redirect:/login?blocked";
        }
        // ... 登录逻辑
    }
}
```

### 2. 注销功能安全问题
**问题描述**：
```java
@GetMapping("/logout")
public String logoutPage(HttpServletRequest request, HttpServletResponse response) {
    String username = request.getUserPrincipal().getName();
    // ... 注销逻辑
}
```
- 使用 GET 方法处理注销请求（可能受到 CSRF 攻击）
- 在注销前获取用户名可能触发 NPE
- Cookie 清理不完整
- 注销状态验证不严格

**建议修复**：
```java
@PostMapping("/logout")
public String logout(HttpServletRequest request, HttpServletResponse response) {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    String username = auth != null ? auth.getName() : "unknown";
    
    try {
        if (auth != null) {
            new SecurityContextLogoutHandler().logout(request, response, auth);
            clearAllCookies(request, response);
            logoutAudit(username, true);
        }
    } catch (Exception e) {
        logger.error("Logout failed for user: " + username, e);
        logoutAudit(username, false);
        return "redirect:/login?error=logout_failed";
    }
    
    return "redirect:/login?logout=success";
}

private void clearAllCookies(HttpServletRequest request, HttpServletResponse response) {
    Cookie[] cookies = request.getCookies();
    if (cookies != null) {
        for (Cookie cookie : cookies) {
            cookie.setValue("");
            cookie.setPath("/");
            cookie.setMaxAge(0);
            response.addCookie(cookie);
        }
    }
}

private void logoutAudit(String username, boolean success) {
    AuditEvent event = new AuditEvent(
        username,
        "LOGOUT",
        success ? "SUCCESS" : "FAILURE"
    );
    auditService.logEvent(event);
}
```

### 3. 会话管理问题
**问题描述**：
- 会话注销后未立即使会话失效
- Cookie 处理不完整
- 缺少会话超时处理
- 没有并发会话控制

**建议修复**：
1. 会话安全配置：
```java
@Configuration
public class SessionConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.sessionManagement()
            .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
            .invalidSessionUrl("/login?invalid")
            .maximumSessions(1)
            .maxSessionsPreventsLogin(true)
            .expiredUrl("/login?expired");
    }
}
```

2. 会话超时配置：
```properties
server.servlet.session.timeout=30m
server.servlet.session.cookie.secure=true
server.servlet.session.cookie.http-only=true
server.servlet.session.cookie.same-site=strict
```

## 安全加强建议

### 1. 认证增强
1. 实现登录尝试限制：
   - 使用 IP 或用户名进行限制
   - 实现指数退避算法
   - 添加验证码机制
   - 记录失败审计日志

2. 密码策略增强：
   - 实现密码复杂度要求
   - 强制定期修改密码
   - 禁止重用最近的密码
   - 密码重置流程安全

### 2. 会话安全
1. 会话管理：
   - 限制并发会话数
   - 实现会话超时
   - 安全的会话创建
   - 完整的会话销毁

2. Cookie 安全：
   - 设置 Secure 标志
   - 设置 HttpOnly 标志
   - 设置 SameSite 属性
   - 适当的过期时间

### 3. 审计日志
1. 关键操作记录：
   - 登录尝试（成功/失败）
   - 密码修改
   - 注销操作
   - 会话操作

2. 日志内容：
   - 时间戳
   - 用户标识
   - 操作类型
   - IP 地址
   - 结果状态

## 风险评估
- 严重程度：高
- 利用难度：中
- 影响范围：认证功能
- 修复优先级：高

## 后续跟踪
- [ ] 实现登录尝试限制
- [ ] 改进注销功能
- [ ] 加强会话安全
- [ ] 完善审计日志
- [ ] 实现密码策略 