---
version: 1.0.0
status: Draft
last_updated: 2024-02-20

# 安全工具类审计报告

## 漏洞信息
- 漏洞ID: VULN-006
- 组件: SecurityUtil.java
- 风险等级: 高
- 影响范围: 全局安全控制

## URL 安全检查问题

### 1. URL 验证不完整
**问题描述**：
```java
public static String checkURL(String url) {
    if (null == url){
        return null;
    }
    // ...
    try {
        URI uri = new URI(url);
        String host = uri.getHost().toLowerCase();
        // ...
    } catch (Exception e) {
        logger.error(e.toString());
        return null;
    }
}
```
- 未验证 URL 格式合法性
- 未处理 URL 编码问题
- 异常处理过于简单
- 日志记录不完整

**建议修复**：
```java
public static String checkURL(String url) {
    if (url == null || url.trim().isEmpty()) {
        logger.warn("URL is null or empty");
        return null;
    }
    
    try {
        // 规范化 URL
        url = normalizeURL(url);
        
        // 验证 URL 格式
        if (!isValidURLFormat(url)) {
            logger.warn("Invalid URL format: {}", url);
            return null;
        }
        
        URI uri = new URI(url);
        String host = uri.getHost();
        if (host == null) {
            logger.warn("No host in URL: {}", url);
            return null;
        }
        host = host.toLowerCase();
        
        // 检查协议
        String scheme = uri.getScheme();
        if (!"http".equalsIgnoreCase(scheme) && !"https".equalsIgnoreCase(scheme)) {
            logger.warn("Invalid scheme: {}", scheme);
            return null;
        }
        
        // 域名检查
        return checkDomain(host, url);
        
    } catch (Exception e) {
        logger.error("Error checking URL: {} - {}", url, e.getMessage(), e);
        return null;
    }
}
```

### 2. SSRF 防护不足
**问题描述**：
```java
@Deprecated
public static boolean checkSSRF(String url) {
    int checkTimes = 10;
    return SSRFChecker.checkSSRF(url, checkTimes);
}
```
- 使用已废弃的方法
- 重定向检查次数固定
- 缺少超时控制
- 未处理 DNS rebinding

**建议修复**：
```java
public static boolean checkSSRF(String url, SSRFConfig config) {
    if (!isValidURL(url)) {
        return false;
    }
    
    try {
        // DNS 解析检查
        if (isDNSRebinding(url)) {
            logger.warn("Detected DNS rebinding attempt: {}", url);
            return false;
        }
        
        // IP 地址检查
        if (isInternalIP(url)) {
            logger.warn("Detected internal IP access attempt: {}", url);
            return false;
        }
        
        // 域名白名单检查
        if (!isWhitelistedDomain(url)) {
            logger.warn("Domain not in whitelist: {}", url);
            return false;
        }
        
        return true;
    } catch (Exception e) {
        logger.error("SSRF check error: {}", e.getMessage(), e);
        return false;
    }
}
```

## 路径遍历防护问题

### 1. 路径过滤不完整
**问题描述**：
```java
public static String pathFilter(String filepath) {
    String temp = filepath;
    while (temp.indexOf('%') != -1) {
        try {
            temp = URLDecoder.decode(temp, "utf-8");
        } catch (UnsupportedEncodingException e) {
            return null;
        }
    }
    if (temp.contains("..") || temp.charAt(0) == '/') {
        return null;
    }
    return filepath;
}
```
- 返回原始路径而不是解码后的路径
- 未处理 Windows 路径分隔符
- 未处理空字节攻击
- 未规范化路径

**建议修复**：
```java
public static String pathFilter(String filepath) {
    if (filepath == null) {
        return null;
    }
    
    try {
        // 解码路径
        String decodedPath = decodeFullPath(filepath);
        if (decodedPath == null) {
            return null;
        }
        
        // 规范化路径
        Path normalizedPath = Paths.get(decodedPath).normalize();
        String normalizedStr = normalizedPath.toString();
        
        // 安全检查
        if (isPathTraversal(normalizedStr) || 
            containsNullByte(normalizedStr) || 
            isAbsolutePath(normalizedStr)) {
            logger.warn("Detected path traversal attempt: {}", filepath);
            return null;
        }
        
        return normalizedStr;
    } catch (Exception e) {
        logger.error("Path filter error: {}", e.getMessage(), e);
        return null;
    }
}
```

## 命令注入防护问题

### 1. 命令过滤不严格
**问题描述**：
```java
public static String cmdFilter(String input) {
    if (!FILTER_PATTERN.matcher(input).matches()) {
        return null;
    }
    return input;
}
```
- 正则表达式可能被绕过
- 未考虑命令拼接问题
- 未处理空白字符
- 未限制命令长度

**建议修复**：
```java
public static class CommandResult {
    private final boolean safe;
    private final String filteredCommand;
    private final String reason;
    
    // ... 构造函数和 getter
}

public static CommandResult cmdFilter(String input) {
    if (input == null || input.trim().isEmpty()) {
        return new CommandResult(false, null, "Empty command");
    }
    
    // 移除多余空白字符
    input = normalizeSpaces(input);
    
    // 长度检查
    if (input.length() > MAX_COMMAND_LENGTH) {
        return new CommandResult(false, null, "Command too long");
    }
    
    // 严格的命令字符白名单
    if (!isValidCommandChars(input)) {
        return new CommandResult(false, null, "Invalid characters");
    }
    
    // 检查危险命令
    if (containsDangerousCommands(input)) {
        return new CommandResult(false, null, "Dangerous command detected");
    }
    
    return new CommandResult(true, input, "OK");
}
```

## SQL 注入防护问题

### 1. SQL 过滤不完整
**问题描述**：
```java
public static String sqlFilter(String sql) {
    if (!FILTER_PATTERN.matcher(sql).matches()) {
        return null;
    }
    return sql;
}
```
- 仅使用简单的正则表达式
- 未处理 SQL 关键字
- 未考虑不同数据库特性
- 未处理编码问题

**建议修复**：
```java
public static class SQLFilterResult {
    private final boolean safe;
    private final String filteredSQL;
    private final String reason;
    
    // ... 构造函数和 getter
}

public static SQLFilterResult sqlFilter(String sql, DatabaseType dbType) {
    if (sql == null || sql.trim().isEmpty()) {
        return new SQLFilterResult(false, null, "Empty SQL");
    }
    
    // 规范化 SQL
    sql = normalizeSQL(sql);
    
    // 检查 SQL 注入特征
    if (containsSQLInjectionPatterns(sql, dbType)) {
        return new SQLFilterResult(false, null, "SQL injection pattern detected");
    }
    
    // 验证 SQL 语法
    if (!isValidSQLSyntax(sql, dbType)) {
        return new SQLFilterResult(false, null, "Invalid SQL syntax");
    }
    
    return new SQLFilterResult(true, sql, "OK");
}
```

## 整体建议

### 1. 安全增强
1. 输入验证：
   - 实现严格的输入验证
   - 使用类型安全的参数
   - 添加长度限制
   - 实现格式验证

2. 错误处理：
   - 改进异常处理
   - 添加详细日志
   - 实现错误恢复
   - 提供错误反馈

3. 安全配置：
   - 使用配置文件
   - 支持动态更新
   - 实现审计日志
   - 添加监控告警

### 2. 代码质量
1. 重构建议：
   - 分离职责
   - 提高可测试性
   - 改进错误处理
   - 添加文档注释

2. 测试建议：
   - 添加单元测试
   - 实现集成测试
   - 进行安全测试
   - 性能测试

## 风险评估
- 严重程度：高
- 利用难度：中
- 影响范围：全局
- 修复优先级：高

## 后续跟踪
- [ ] 改进 URL 验证
- [ ] 加强 SSRF 防护
- [ ] 完善路径过滤
- [ ] 增强命令过滤
- [ ] 改进 SQL 过滤
- [ ] 添加单元测试
- [ ] 实现监控告警 