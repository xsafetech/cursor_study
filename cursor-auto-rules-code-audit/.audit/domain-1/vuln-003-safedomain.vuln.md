---
version: 1.0.0
status: Draft
last_updated: 2024-02-20

# 安全域名配置漏洞报告

## 漏洞信息
- 漏洞ID: VULN-003
- 组件: SafeDomainParser.java
- 风险等级: 高
- 影响范围: URL安全检查和SSRF防护

## XML 解析安全问题

### 1. XML 外部实体注入风险
**问题描述**：
```java
DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
DocumentBuilder db = dbf.newDocumentBuilder();
Document doc = db.parse(file);
```
- 未禁用 XML 外部实体解析
- 未设置安全相关的特性
- 可能导致 XXE 漏洞

**建议修复**：
```java
DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
dbf.setFeature("http://xml.org/sax/features/external-general-entities", false);
dbf.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
dbf.setXIncludeAware(false);
dbf.setExpandEntityReferences(false);
```

### 2. 文件路径处理问题
**问题描述**：
```java
String safeDomainClassPath = "url" + File.separator + "url_safe_domain.xml";
File file = resource.getFile();
```
- 使用文件系统分隔符可能导致跨平台问题
- 直接获取文件可能导致路径遍历
- 缺少文件存在性检查

## 错误处理问题

### 1. 异常处理不当
**问题描述**：
```java
} catch (Exception e) {
    logger.error(e.toString());
}
```
- 捕获了通用 Exception
- 仅记录日志，未进行适当处理
- 可能导致静默失败

### 2. 空值处理
**问题描述**：
```java
@Bean
public SafeDomainParser safeDomainParser() {
    try {
        return new SafeDomainParser();
    } catch (Exception e) {
        LOGGER.error("SafeDomainParser is null " + e.getMessage(), e);
    }
    return null;
}
```
- 返回 null 可能导致 NullPointerException
- 缺少错误恢复机制
- 缺少默认配置

## 配置加载问题

### 1. 配置验证不足
**问题描述**：
- 未验证加载的域名格式
- 未检查重复域名
- 未验证 IP 地址格式
- 缺少配置完整性检查

### 2. 内存安全
**问题描述**：
- ArrayList 大小未限制
- 可能导致内存溢出
- 缺少配置项数量限制

## 建议修复

### 1. XML 解析安全加强
```java
public class SafeDomainParser {
    private static final int MAX_DOMAINS = 1000;
    private final DocumentBuilderFactory dbf;
    
    public SafeDomainParser() {
        dbf = DocumentBuilderFactory.newInstance();
        // 设置安全特性
        setSecureFeatures(dbf);
    }
    
    private void setSecureFeatures(DocumentBuilderFactory factory) {
        try {
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            factory.setXIncludeAware(false);
            factory.setExpandEntityReferences(false);
        } catch (ParserConfigurationException e) {
            throw new SecurityException("Failed to configure XML parser", e);
        }
    }
}
```

### 2. 错误处理改进
```java
@Bean
public SafeDomainParser safeDomainParser() {
    try {
        SafeDomainParser parser = new SafeDomainParser();
        if (!parser.isValid()) {
            throw new ConfigurationException("Invalid safe domain configuration");
        }
        return parser;
    } catch (Exception e) {
        LOGGER.error("Failed to initialize SafeDomainParser", e);
        return new SafeDomainParser(getDefaultConfig());
    }
}
```

### 3. 配置验证加强
```java
private void validateDomains(List<String> domains) {
    if (domains.size() > MAX_DOMAINS) {
        throw new ConfigurationException("Too many domains");
    }
    
    for (String domain : domains) {
        if (!isValidDomain(domain)) {
            throw new ConfigurationException("Invalid domain: " + domain);
        }
    }
}

private void validateIPs(List<String> ips) {
    for (String ip : ips) {
        if (!isValidIP(ip)) {
            throw new ConfigurationException("Invalid IP: " + ip);
        }
    }
}
```

## 风险评估
- 严重程度：高
- 利用难度：中
- 影响范围：全局配置
- 修复优先级：高

## 后续跟踪
- [ ] 实现 XML 解析安全加强
- [ ] 改进错误处理机制
- [ ] 添加配置验证
- [ ] 实现默认配置
- [ ] 添加配置审计日志 