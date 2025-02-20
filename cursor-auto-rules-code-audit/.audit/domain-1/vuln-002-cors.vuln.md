---
version: 1.0.0
status: Draft
last_updated: 2024-02-20

# CORS 配置漏洞报告

## 漏洞信息
- 漏洞ID: VULN-002
- 组件: CorsConfig2.java
- 风险等级: 中
- 影响范围: CORS 安全配置

## 发现的问题

### 1. 重复的 CORS 配置
**问题描述**：
- 项目中存在多处 CORS 配置：
  1. WebSecurityConfig.java 中的全局配置
  2. CorsConfig2.java 中的过滤器配置
- 多处配置可能导致混淆和冲突

**影响**：
- CORS 策略可能不一致
- 可能出现配置覆盖
- 增加维护难度和出错风险

### 2. CORS 配置范围限制
**问题描述**：
```java
source.registerCorsConfiguration("/cors/getCsrfToken/sec_03", config);
```
- CORS 配置仅限于特定端点
- 其他需要 CORS 的端点可能未被正确配置

### 3. 配置项安全性
**问题描述**：
```java
config.setAllowCredentials(true);
config.addAllowedHeader("*");
```
- 允许所有请求头
- 启用了 credentials 但同时配置了多个源
- 混合使用 HTTP 和 HTTPS

## 配置比对

### WebSecurityConfig.java 中的配置：
```java
allowOrigins.add("joychou.org");
allowOrigins.add("https://test.joychou.me");
```

### CorsConfig2.java 中的配置：
```java
config.addAllowedOrigin("http://test.joychou.org");
config.addAllowedOrigin("https://test.joychou.org");
```

**问题**：
- 配置不一致
- 域名策略不统一
- 协议使用混乱

## 建议修复

### 1. 统一 CORS 配置
```java
@Configuration
public class CorsConfig {
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(Arrays.asList(
            "https://test.joychou.org"
        ));
        config.setAllowCredentials(true);
        config.setAllowedMethods(Arrays.asList("GET", "POST"));
        config.setAllowedHeaders(Arrays.asList(
            "Authorization", 
            "Content-Type",
            "X-Requested-With"
        ));
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
```

### 2. 安全加强建议
1. 配置规范化：
   - 统一使用 HTTPS
   - 明确指定允许的请求头
   - 限制允许的请求方法
   - 谨慎配置 allowCredentials

2. 最佳实践：
   - 避免使用通配符
   - 实现细粒度的控制
   - 记录 CORS 请求日志
   - 定期审查配置

## 风险评估
- 严重程度：中
- 利用难度：中
- 影响范围：跨域请求
- 修复优先级：中

## 后续跟踪
- [ ] 统一 CORS 配置
- [ ] 移除重复配置
- [ ] 更新域名白名单
- [ ] 加强安全限制
- [ ] 实现配置审计 