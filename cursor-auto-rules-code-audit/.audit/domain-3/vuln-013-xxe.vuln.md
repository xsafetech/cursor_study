---
version: 1.0.0
status: Draft
last_updated: 2024-02-20

# XXE 漏洞审计报告

## 漏洞信息
- 漏洞ID: VULN-013
- 组件: XXE.java
- 风险等级: 高
- 影响范围: XML 解析功能

## 漏洞描述

### 1. XMLReader 不安全配置
**问题代码**：
```java
@PostMapping("/xmlReader/vuln")
public String xmlReaderVuln(HttpServletRequest request) {
    try {
        String body = WebUtils.getRequestBody(request);
        logger.info(body);
        XMLReader xmlReader = XMLReaderFactory.createXMLReader();
        xmlReader.parse(new InputSource(new StringReader(body)));
        return "xmlReader xxe vuln code";
    } catch (Exception e) {
        logger.error(e.toString());
        return EXCEPT;
    }
}
```
- 未禁用外部实体解析
- 未禁用 DOCTYPE 声明
- 未限制实体扩展
- 错误处理不完整

**影响**：
- 可能导致信息泄露
- 可能导致服务器文件读取
- 可能导致内网探测
- 可能导致拒绝服务

### 2. DocumentBuilder 不安全配置
**问题代码**：
```java
@RequestMapping(value = "/DocumentBuilder/vuln", method = RequestMethod.POST)
public String DocumentBuilderVuln(HttpServletRequest request) {
    try {
        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        DocumentBuilder db = dbf.newDocumentBuilder();
        InputSource is = new InputSource(request.getInputStream());
        Document document = db.parse(is);
        // ...
    } catch (Exception e) {
        logger.error(e.toString());
        return EXCEPT;
    }
}
```
- 未设置安全特性
- 允许外部实体访问
- 允许 XInclude 处理
- 错误处理不完善

### 3. 其他不安全的 XML 解析器
包括：
- SAXBuilder
- SAXReader
- SAXParser
- Digester
- DocumentHelper

这些解析器都存在类似的安全配置缺失问题。

## 安全实现示例

### 1. 安全的 XMLReader 配置
```java
public class SecureXMLReader {
    public static XMLReader createSecureXMLReader() throws Exception {
        XMLReader reader = XMLReaderFactory.createXMLReader();
        
        // 禁用外部实体
        reader.setFeature(
            "http://xml.org/sax/features/external-general-entities",
            false
        );
        reader.setFeature(
            "http://xml.org/sax/features/external-parameter-entities",
            false
        );
        
        // 禁用 DOCTYPE 声明
        reader.setFeature(
            "http://apache.org/xml/features/disallow-doctype-decl",
            true
        );
        
        // 限制实体扩展
        reader.setFeature(
            "http://apache.org/xml/features/nonvalidating/load-external-dtd",
            false
        );
        
        return reader;
    }
    
    public static String parseXML(String xml) throws Exception {
        try {
            XMLReader reader = createSecureXMLReader();
            InputSource source = new InputSource(new StringReader(xml));
            reader.parse(source);
            return "XML parsed securely";
        } catch (Exception e) {
            logger.error("XML parsing error", e);
            throw new SecurityException("XML parsing failed");
        }
    }
}
```

### 2. 安全的 DocumentBuilder 配置
```java
public class SecureDocumentBuilder {
    public static DocumentBuilder createSecureDocumentBuilder() 
            throws Exception {
        DocumentBuilderFactory factory = 
            DocumentBuilderFactory.newInstance();
        
        // 基本安全配置
        factory.setFeature(
            "http://apache.org/xml/features/disallow-doctype-decl",
            true
        );
        factory.setFeature(
            "http://xml.org/sax/features/external-general-entities",
            false
        );
        factory.setFeature(
            "http://xml.org/sax/features/external-parameter-entities",
            false
        );
        
        // 禁用 XInclude
        factory.setXIncludeAware(false);
        
        // 禁用扩展
        factory.setExpandEntityReferences(false);
        
        // 创建安全的构建器
        return factory.newDocumentBuilder();
    }
    
    public static Document parseXML(InputStream input) throws Exception {
        try {
            DocumentBuilder builder = createSecureDocumentBuilder();
            return builder.parse(new InputSource(input));
        } catch (Exception e) {
            logger.error("XML parsing error", e);
            throw new SecurityException("XML parsing failed");
        }
    }
}
```

### 3. XML 解析器通用安全配置
```java
public class XMLParserSecurityConfig {
    // 安全特性配置
    private static final Map<String, Boolean> SECURITY_FEATURES;
    static {
        SECURITY_FEATURES = new HashMap<>();
        SECURITY_FEATURES.put(
            "http://apache.org/xml/features/disallow-doctype-decl",
            true
        );
        SECURITY_FEATURES.put(
            "http://xml.org/sax/features/external-general-entities",
            false
        );
        SECURITY_FEATURES.put(
            "http://xml.org/sax/features/external-parameter-entities",
            false
        );
        SECURITY_FEATURES.put(
            "http://apache.org/xml/features/nonvalidating/load-external-dtd",
            false
        );
    }
    
    // 应用安全配置
    public static void applySecurityFeatures(Object parser) 
            throws Exception {
        Method setFeature = null;
        
        // 获取 setFeature 方法
        for (Method method : parser.getClass().getMethods()) {
            if ("setFeature".equals(method.getName())) {
                setFeature = method;
                break;
            }
        }
        
        if (setFeature != null) {
            // 应用所有安全特性
            for (Map.Entry<String, Boolean> feature : 
                    SECURITY_FEATURES.entrySet()) {
                setFeature.invoke(
                    parser,
                    feature.getKey(),
                    feature.getValue()
                );
            }
        }
    }
}
```

## 修复建议

### 1. 代码层面
1. XML 解析器配置：
   - 禁用外部实体
   - 禁用 DOCTYPE 声明
   - 禁用实体扩展
   - 禁用 XInclude

2. 输入验证：
   - 验证 XML 格式
   - 限制 XML 大小
   - 过滤特殊字符
   - 验证 DTD 引用

3. 错误处理：
   - 统一异常处理
   - 安全的错误消息
   - 完整的日志记录
   - 资源释放保证

### 2. 架构层面
1. 安全策略：
   - 统一的 XML 解析配置
   - 集中的安全控制
   - 标准的处理流程
   - 完整的安全文档

2. 防护措施：
   - WAF 规则配置
   - 入侵检测
   - 实时监控
   - 安全审计

3. 运行时防护：
   - 资源限制
   - 超时控制
   - 并发控制
   - 异常监控

## 风险评估
- 严重程度：高
- 利用难度：低
- 影响范围：全局
- 修复优先级：高

## 后续跟踪
- [ ] 修复不安全的 XML 解析
- [ ] 统一安全配置
- [ ] 加强输入验证
- [ ] 改进错误处理
- [ ] 实现安全防护
- [ ] 添加安全测试
- [ ] 更新安全基线
- [ ] 培训开发人员 