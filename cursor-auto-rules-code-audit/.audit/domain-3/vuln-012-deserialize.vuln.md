---
version: 1.0.0
status: Draft
last_updated: 2024-02-20

# 反序列化漏洞审计报告

## 漏洞信息
- 漏洞ID: VULN-012
- 组件: Deserialize.java
- 风险等级: 高
- 影响范围: 反序列化功能

## 漏洞描述

### 1. 不安全的 Java 反序列化
**问题代码**：
```java
@RequestMapping("/rememberMe/vuln")
public String rememberMeVul(HttpServletRequest request)
        throws IOException, ClassNotFoundException {
    Cookie cookie = getCookie(request, Constants.REMEMBER_ME_COOKIE);
    if (null == cookie) {
        return "No rememberMe cookie. Right?";
    }
    String rememberMe = cookie.getValue();
    byte[] decoded = Base64.getDecoder().decode(rememberMe);
    ByteArrayInputStream bytes = new ByteArrayInputStream(decoded);
    ObjectInputStream in = new ObjectInputStream(bytes);
    in.readObject();
    in.close();
    return "Are u ok?";
}
```
- 直接使用 ObjectInputStream 进行反序列化
- 未对反序列化的类进行限制
- 未进行类型验证
- 错误处理不完整

**影响**：
- 可能导致远程代码执行
- 可能导致服务器被入侵
- 可能导致数据泄露
- 可能导致拒绝服务

### 2. 不安全的 Jackson 反序列化
**问题代码**：
```java
@RequestMapping("/jackson")
public void Jackson(String payload) {
    ObjectMapper mapper = new ObjectMapper();
    mapper.enableDefaultTyping();
    try {
        Object obj = mapper.readValue(payload, Object.class);
        mapper.writeValueAsString(obj);
    } catch (IOException e) {
        e.printStackTrace();
    }
}
```
- 启用了不安全的类型转换
- 未限制反序列化的类型
- 错误处理不完善
- 可能导致 JNDI 注入

**影响**：
1. 安全风险：
   - 可以执行任意代码
   - 可以进行 JNDI 注入
   - 可以访问内部资源
   - 可以绕过安全限制

2. 漏洞利用：
   - Commons-Collections 利用链
   - JNDI 注入利用链
   - Spring 框架利用链
   - 其他反序列化利用链

## 安全实现示例

### 1. 安全的 Java 反序列化
```java
public class SecureObjectInputStream extends ObjectInputStream {
    private static final Set<String> ALLOWED_CLASSES = new HashSet<>(Arrays.asList(
        "java.util.ArrayList",
        "java.util.HashMap"
        // 添加其他允许的类
    ));

    public SecureObjectInputStream(InputStream in) throws IOException {
        super(in);
    }

    @Override
    protected Class<?> resolveClass(ObjectStreamClass desc) 
            throws IOException, ClassNotFoundException {
        String className = desc.getName();
        
        // 验证类名是否在白名单中
        if (!ALLOWED_CLASSES.contains(className)) {
            throw new InvalidClassException(
                "Unauthorized deserialization attempt", className);
        }
        
        return super.resolveClass(desc);
    }
}

// 使用示例
@RequestMapping("/deserialize/safe")
public String deserializeSafe(HttpServletRequest request) 
        throws IOException, ClassNotFoundException {
    try {
        Cookie cookie = getCookie(request, COOKIE_NAME);
        if (cookie == null) {
            return "No cookie found";
        }

        byte[] data = Base64.getDecoder().decode(cookie.getValue());
        try (ByteArrayInputStream bis = new ByteArrayInputStream(data);
             SecureObjectInputStream ois = new SecureObjectInputStream(bis)) {
            
            Object obj = ois.readObject();
            // 处理反序列化后的对象
            return "Deserialization successful";
        }
    } catch (InvalidClassException e) {
        logger.warn("Unauthorized deserialization attempt", e);
        return "Security violation detected";
    } catch (Exception e) {
        logger.error("Deserialization error", e);
        return "Error processing request";
    }
}
```

### 2. 安全的 Jackson 配置
```java
@Configuration
public class JacksonConfig {
    @Bean
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        
        // 禁用默认类型处理
        mapper.disableDefaultTyping();
        
        // 配置安全的反序列化
        mapper.configure(
            DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, 
            true
        );
        
        // 注册自定义的反序列化器
        SimpleModule module = new SimpleModule();
        module.addDeserializer(
            Object.class, 
            new SecureDeserializer()
        );
        mapper.registerModule(module);
        
        return mapper;
    }
}

public class SecureDeserializer extends JsonDeserializer<Object> {
    private static final Set<String> ALLOWED_PACKAGES = new HashSet<>(
        Arrays.asList(
            "org.example.model",
            "java.util"
        )
    );

    @Override
    public Object deserialize(JsonParser p, DeserializationContext ctxt) 
            throws IOException {
        JsonNode node = p.getCodec().readTree(p);
        
        // 验证类型信息
        if (node.has("@class")) {
            String className = node.get("@class").asText();
            if (!isAllowedClass(className)) {
                throw new JsonMappingException(
                    p, 
                    "Unauthorized class: " + className
                );
            }
        }
        
        // 继续正常的反序列化
        return ctxt.readValue(p, Object.class);
    }

    private boolean isAllowedClass(String className) {
        return ALLOWED_PACKAGES.stream()
            .anyMatch(className::startsWith);
    }
}
```

## 修复建议

### 1. 代码层面
1. Java 反序列化：
   - 实现类白名单验证
   - 使用自定义 ObjectInputStream
   - 实现反序列化过滤器
   - 完善错误处理

2. Jackson 配置：
   - 禁用默认类型处理
   - 配置类型白名单
   - 实现自定义反序列化器
   - 加强输入验证

3. 通用建议：
   - 使用安全的序列化格式
   - 实现完整的验证机制
   - 加强错误处理
   - 实现审计日志

### 2. 架构层面
1. 序列化策略：
   - 使用安全的序列化方案
   - 实现数据验证机制
   - 配置访问控制
   - 实现数据隔离

2. 安全防护：
   - 实现反序列化防护
   - 配置 WAF 规则
   - 实现入侵检测
   - 监控异常行为

3. 运行时防护：
   - JVM 安全配置
   - 类加载器限制
   - 资源访问控制
   - 实时监控

## 风险评估
- 严重程度：高
- 利用难度：中
- 影响范围：全局
- 修复优先级：高

## 后续跟踪
- [ ] 修复不安全的反序列化
- [ ] 完善 Jackson 配置
- [ ] 加强输入验证
- [ ] 改进错误处理
- [ ] 实现安全防护
- [ ] 添加安全测试
- [ ] 更新安全基线
- [ ] 培训开发人员