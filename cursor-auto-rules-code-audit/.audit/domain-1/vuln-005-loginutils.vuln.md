---
version: 1.0.0
status: Draft
last_updated: 2024-02-20

# 登录工具类安全审计报告

## 漏洞信息
- 漏洞ID: VULN-005
- 组件: LoginUtils.java
- 风险等级: 中
- 影响范围: 用户信息处理

## 发现的问题

### 1. 用户信息处理不安全
**问题描述**：
```java
public static String getUserInfo2JsonStr(HttpServletRequest request) {
    Principal principal = request.getUserPrincipal();
    String username = principal.getName();
    Map<String, String> m = new HashMap<>();
    m.put("Username", username);
    return JSON.toJSONString(m);
}
```
- 未进行空值检查
- 使用了不安全的 Fastjson 序列化
- 缺少异常处理
- 敏感信息直接返回

**潜在影响**：
1. 空指针异常：
   - 当 principal 为 null 时会抛出 NPE
   - 可能导致应用程序崩溃
   - 可能泄露错误堆栈信息

2. 序列化安全：
   - Fastjson 存在已知的安全漏洞
   - 可能导致反序列化攻击
   - 版本依赖管理不当可能引入漏洞

3. 信息泄露：
   - 用户名直接暴露在 JSON 中
   - 缺少数据脱敏处理
   - 可能泄露敏感信息

**建议修复**：
```java
public class LoginUtils {
    private static final Logger logger = LoggerFactory.getLogger(LoginUtils.class);
    
    public static String getUserInfo2JsonStr(HttpServletRequest request) {
        try {
            // 空值检查
            if (request == null) {
                throw new IllegalArgumentException("Request cannot be null");
            }
            
            Principal principal = request.getUserPrincipal();
            if (principal == null) {
                return createAnonymousUserJson();
            }
            
            // 用户信息脱敏和安全处理
            String username = principal.getName();
            Map<String, String> userInfo = createSafeUserInfo(username);
            
            // 使用更安全的序列化方式
            return serializeUserInfo(userInfo);
            
        } catch (Exception e) {
            logger.error("Error getting user info", e);
            return createErrorResponse();
        }
    }
    
    private static Map<String, String> createSafeUserInfo(String username) {
        Map<String, String> info = new HashMap<>();
        info.put("username", maskUsername(username));
        return info;
    }
    
    private static String maskUsername(String username) {
        if (username == null || username.length() < 3) {
            return "***";
        }
        return username.charAt(0) + 
               "*".repeat(username.length() - 2) + 
               username.charAt(username.length() - 1);
    }
    
    private static String createAnonymousUserJson() {
        Map<String, String> anonymous = new HashMap<>();
        anonymous.put("username", "anonymous");
        return serializeUserInfo(anonymous);
    }
    
    private static String createErrorResponse() {
        Map<String, String> error = new HashMap<>();
        error.put("error", "Unable to process user information");
        return serializeUserInfo(error);
    }
    
    private static String serializeUserInfo(Map<String, String> info) {
        // 使用更安全的 JSON 序列化方式
        ObjectMapper mapper = new ObjectMapper();
        try {
            return mapper.writeValueAsString(info);
        } catch (JsonProcessingException e) {
            logger.error("Error serializing user info", e);
            return "{}";
        }
    }
}
```

### 2. 安全功能缺失
**问题描述**：
1. 缺少必要的安全功能：
   - 没有会话验证
   - 没有权限检查
   - 没有访问控制
   - 没有审计日志

2. 工具类设计问题：
   - 静态方法可能导致测试困难
   - 缺少配置灵活性
   - 职责划分不清晰
   - 扩展性受限

**建议改进**：
```java
@Component
public class LoginService {
    private final UserAuditService auditService;
    private final SecurityConfig securityConfig;
    private final ObjectMapper objectMapper;
    
    public LoginService(
            UserAuditService auditService,
            SecurityConfig securityConfig,
            ObjectMapper objectMapper) {
        this.auditService = auditService;
        this.securityConfig = securityConfig;
        this.objectMapper = objectMapper;
    }
    
    public UserInfo getCurrentUser(HttpServletRequest request) {
        try {
            validateRequest(request);
            UserInfo userInfo = extractUserInfo(request);
            auditUserAccess(userInfo);
            return userInfo;
        } catch (SecurityException e) {
            handleSecurityViolation(e);
            throw e;
        }
    }
    
    private void validateRequest(HttpServletRequest request) {
        if (!isValidSession(request)) {
            throw new SecurityException("Invalid session");
        }
    }
    
    private void auditUserAccess(UserInfo userInfo) {
        auditService.logAccess(
            userInfo.getUsername(),
            "USER_INFO_ACCESS",
            true
        );
    }
}
```

## 安全建议

### 1. 输入验证
- 实现请求验证
- 添加参数检查
- 实现会话验证
- 添加访问控制

### 2. 数据处理
- 实现数据脱敏
- 使用安全的序列化
- 添加错误处理
- 规范异常处理

### 3. 安全功能
- 添加审计日志
- 实现访问控制
- 添加会话验证
- 实现权限检查

### 4. 代码质量
- 改进类设计
- 添加单元测试
- 实现依赖注入
- 提高可维护性

## 风险评估
- 严重程度：中
- 利用难度：中
- 影响范围：用户信息处理
- 修复优先级：中

## 后续跟踪
- [ ] 实现安全的序列化
- [ ] 添加异常处理
- [ ] 实现数据脱敏
- [ ] 添加审计日志
- [ ] 改进类设计 