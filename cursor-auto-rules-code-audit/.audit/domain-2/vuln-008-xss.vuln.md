---
version: 1.0.0
status: Draft
last_updated: 2024-02-20

# XSS 漏洞审计报告

## 漏洞信息
- 漏洞ID: VULN-008
- 组件: XSS.java
- 风险等级: 高
- 影响范围: Web 前端展示层

## 漏洞描述

### 1. 反射型 XSS 漏洞
**问题代码**：
```java
@RequestMapping("/reflect")
@ResponseBody
public static String reflect(String xss) {
    return xss;
}
```
- 直接返回未经处理的用户输入
- 没有进行任何转义或过滤
- 没有设置安全响应头
- 没有实现 CSP

**影响**：
- 可以执行任意 JavaScript 代码
- 可能导致用户信息泄露
- 可能导致会话劫持
- 可能导致钓鱼攻击

### 2. 存储型 XSS 漏洞
**问题代码**：
```java
@RequestMapping("/stored/store")
@ResponseBody
public String store(String xss, HttpServletResponse response) {
    Cookie cookie = new Cookie("xss", xss);
    response.addCookie(cookie);
    return "Set param into cookie";
}

@RequestMapping("/stored/show")
@ResponseBody
public String show(@CookieValue("xss") String xss) {
    return xss;
}
```
- 将未经处理的用户输入存储在 Cookie 中
- 读取 Cookie 时未进行转义
- Cookie 没有设置安全属性
- 没有实现输入验证

**影响**：
1. 存储阶段：
   - 恶意代码被持久化
   - Cookie 污染
   - 可能影响其他用户
   - 持续性攻击

2. 显示阶段：
   - 执行存储的恶意代码
   - 影响多个用户
   - 难以清除
   - 扩大攻击面

### 3. 不完整的 XSS 防护
**问题代码**：
```java
private static String encode(String origin) {
    origin = StringUtils.replace(origin, "&", "&amp;");
    origin = StringUtils.replace(origin, "<", "&lt;");
    origin = StringUtils.replace(origin, ">", "&gt;");
    origin = StringUtils.replace(origin, "\"", "&quot;");
    origin = StringUtils.replace(origin, "'", "&#x27;");
    origin = StringUtils.replace(origin, "/", "&#x2F;");
    return origin;
}
```
- 编码实现不完整
- 未考虑所有 XSS 向量
- 未处理 JavaScript 事件
- 未处理 CSS 注入

## 安全实现示例

### 1. 反射型 XSS 防护
```java
@RequestMapping("/reflect")
@ResponseBody
public static String reflectSafe(String input) {
    if (input == null) {
        return "";
    }
    // 输入验证
    if (!InputValidator.isValid(input)) {
        throw new IllegalArgumentException("Invalid input");
    }
    // HTML 编码
    String encoded = HtmlUtils.htmlEscape(input);
    // JavaScript 编码
    encoded = JavaScriptUtils.javaScriptEscape(encoded);
    return encoded;
}
```

### 2. 存储型 XSS 防护
```java
@RequestMapping("/stored/store")
@ResponseBody
public String storeSafe(String input, HttpServletResponse response) {
    if (input == null) {
        return "Input is required";
    }
    // 输入验证
    if (!InputValidator.isValid(input)) {
        throw new IllegalArgumentException("Invalid input");
    }
    // HTML 编码
    String encoded = HtmlUtils.htmlEscape(input);
    // 设置安全的 Cookie
    Cookie cookie = new Cookie("data", encoded);
    cookie.setHttpOnly(true);
    cookie.setSecure(true);
    cookie.setSameSite("Strict");
    response.addCookie(cookie);
    return "Data stored safely";
}
```

### 3. 完整的 XSS 防护
```java
public class XSSUtils {
    // HTML 编码
    public static String encodeHtml(String input) {
        return HtmlUtils.htmlEscape(input);
    }
    
    // JavaScript 编码
    public static String encodeJavaScript(String input) {
        return JavaScriptUtils.javaScriptEscape(input);
    }
    
    // CSS 编码
    public static String encodeCss(String input) {
        return CssUtils.cssEscape(input);
    }
    
    // URL 编码
    public static String encodeUrl(String input) {
        return URLEncoder.encode(input, StandardCharsets.UTF_8);
    }
    
    // 属性编码
    public static String encodeAttribute(String input) {
        return AttributeUtils.attributeEscape(input);
    }
}
```

## 修复建议

### 1. 代码层面
1. 输入验证：
   - 实现白名单验证
   - 限制输入长度
   - 验证数据类型
   - 过滤特殊字符

2. 输出编码：
   - HTML 编码
   - JavaScript 编码
   - CSS 编码
   - URL 编码
   - 属性编码

3. 响应头设置：
   - Content-Type
   - X-XSS-Protection
   - Content-Security-Policy
   - X-Content-Type-Options

### 2. 架构层面
1. 安全框架：
   - 使用 ESAPI
   - 配置 CSP
   - 实现 XSS 过滤器
   - 统一安全控制

2. 开发规范：
   - 模板引擎
   - 安全编码规范
   - 代码审查
   - 安全测试

3. 运行时防护：
   - WAF 配置
   - 实时监控
   - 攻击检测
   - 响应处理

## 风险评估
- 严重程度：高
- 利用难度：低
- 影响范围：全局
- 修复优先级：高

## 后续跟踪
- [ ] 修复反射型 XSS
- [ ] 修复存储型 XSS
- [ ] 完善 XSS 防护
- [ ] 配置安全响应头
- [ ] 实现 CSP
- [ ] 更新编码工具类
- [ ] 添加安全测试
- [ ] 培训开发人员 