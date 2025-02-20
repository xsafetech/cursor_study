---
version: 1.0.0
status: Draft
last_updated: 2024-02-20

# SSRF 漏洞审计报告

## 漏洞信息
- 漏洞ID: VULN-014
- 组件: SSRF.java
- 风险等级: 高
- 影响范围: URL 请求功能

## 漏洞描述

### 1. URLConnection 不安全使用
**问题代码**：
```java
@RequestMapping(value = "/urlConnection/vuln", method = {RequestMethod.POST, RequestMethod.GET})
public String URLConnectionVuln(String url) {
    return HttpUtils.URLConnection(url);
}
```
- 直接使用用户输入的 URL
- 未进行协议限制
- 未进行域名验证
- 允许重定向

**影响**：
- 可能访问内网资源
- 可能读取本地文件
- 可能进行端口扫描
- 可能绕过防火墙

### 2. HttpURLConnection 不安全使用
**问题代码**：
```java
@GetMapping("/HttpURLConnection/vuln")
public String httpURLConnectionVuln(@RequestParam String url) {
    return HttpUtils.HttpURLConnection(url);
}
```
- 未验证 URL 合法性
- 未限制请求范围
- 未处理重定向
- 错误处理不完整

### 3. 文件下载 SSRF
**问题代码**：
```java
@GetMapping("/openStream")
public void openStream(@RequestParam String url, HttpServletResponse response) 
        throws IOException {
    InputStream inputStream = null;
    OutputStream outputStream = null;
    try {
        String downLoadImgFileName = WebUtils.getNameWithoutExtension(url) 
            + "." + WebUtils.getFileExtension(url);
        response.setHeader("content-disposition", 
            "attachment;fileName=" + downLoadImgFileName);

        URL u = new URL(url);
        int length;
        byte[] bytes = new byte[1024];
        inputStream = u.openStream();
        outputStream = response.getOutputStream();
        while ((length = inputStream.read(bytes)) > 0) {
            outputStream.write(bytes, 0, length);
        }
    } catch (Exception e) {
        logger.error(e.toString());
    } finally {
        if (inputStream != null) {
            inputStream.close();
        }
        if (outputStream != null) {
            outputStream.close();
        }
    }
}
```
- 直接使用用户输入的 URL
- 未验证文件类型
- 未限制下载大小
- 错误处理不完善

### 4. DNS 重绑定攻击
**问题代码**：
```java
@GetMapping("/dnsrebind/vuln")
public String DnsRebind(String url) {
    return HttpUtils.URLConnection(url);
}
```
- 未进行 DNS 重绑定防护
- 未实现 IP 地址缓存
- 未验证多次解析结果
- 可能绕过域名白名单

## 安全实现示例

### 1. 安全的 URL 请求
```java
public class SecureURLConnection {
    private static final Set<String> ALLOWED_PROTOCOLS = 
        new HashSet<>(Arrays.asList("http", "https"));
    
    private static final Set<String> ALLOWED_DOMAINS = 
        new HashSet<>(Arrays.asList(
            "example.com",
            "api.example.com"
        ));
    
    public static String sendRequest(String url) throws Exception {
        // URL 基本验证
        if (!isValidUrl(url)) {
            throw new SecurityException("Invalid URL");
        }
        
        // 协议验证
        URL parsedUrl = new URL(url);
        if (!ALLOWED_PROTOCOLS.contains(parsedUrl.getProtocol())) {
            throw new SecurityException("Protocol not allowed");
        }
        
        // 域名验证
        String host = parsedUrl.getHost();
        if (!isAllowedDomain(host)) {
            throw new SecurityException("Domain not allowed");
        }
        
        // IP 地址验证
        InetAddress addr = InetAddress.getByName(host);
        if (!isAllowedIP(addr)) {
            throw new SecurityException("IP not allowed");
        }
        
        // 发送请求
        HttpURLConnection conn = null;
        try {
            conn = (HttpURLConnection) parsedUrl.openConnection();
            conn.setInstanceFollowRedirects(false);
            
            // 设置超时
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);
            
            // 读取响应
            return readResponse(conn);
        } finally {
            if (conn != null) {
                conn.disconnect();
            }
        }
    }
    
    private static boolean isValidUrl(String url) {
        try {
            new URL(url);
            return true;
        } catch (MalformedURLException e) {
            return false;
        }
    }
    
    private static boolean isAllowedDomain(String host) {
        return ALLOWED_DOMAINS.stream()
            .anyMatch(domain -> host.endsWith("." + domain) 
                || host.equals(domain));
    }
    
    private static boolean isAllowedIP(InetAddress addr) {
        byte[] bytes = addr.getAddress();
        
        // 禁止内网 IP
        if (addr.isLoopbackAddress() || 
            addr.isLinkLocalAddress() || 
            addr.isSiteLocalAddress()) {
            return false;
        }
        
        // 自定义 IP 验证规则
        // ...
        
        return true;
    }
}
```

### 2. 安全的文件下载
```java
public class SecureFileDownload {
    private static final int MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
    private static final Set<String> ALLOWED_EXTENSIONS = 
        new HashSet<>(Arrays.asList("jpg", "png", "pdf"));
    
    public static void downloadFile(String url, 
            HttpServletResponse response) throws Exception {
        // URL 验证
        URL fileUrl = validateUrl(url);
        
        // 文件类型验证
        String extension = getFileExtension(url);
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new SecurityException("File type not allowed");
        }
        
        // 下载文件
        HttpURLConnection conn = null;
        InputStream input = null;
        OutputStream output = null;
        
        try {
            conn = (HttpURLConnection) fileUrl.openConnection();
            conn.setInstanceFollowRedirects(false);
            
            // 验证文件大小
            int contentLength = conn.getContentLength();
            if (contentLength > MAX_FILE_SIZE) {
                throw new SecurityException("File too large");
            }
            
            // 验证 Content-Type
            String contentType = conn.getContentType();
            if (!isAllowedContentType(contentType)) {
                throw new SecurityException("Content-Type not allowed");
            }
            
            // 设置响应头
            response.setContentType(contentType);
            response.setHeader("Content-Disposition", 
                "attachment; filename=\"" + 
                sanitizeFileName(getFileName(url)) + "\"");
            
            // 复制文件内容
            input = conn.getInputStream();
            output = response.getOutputStream();
            
            byte[] buffer = new byte[4096];
            int bytesRead;
            int totalBytes = 0;
            
            while ((bytesRead = input.read(buffer)) != -1) {
                totalBytes += bytesRead;
                if (totalBytes > MAX_FILE_SIZE) {
                    throw new SecurityException("File too large");
                }
                output.write(buffer, 0, bytesRead);
            }
            
        } finally {
            if (input != null) input.close();
            if (output != null) output.close();
            if (conn != null) conn.disconnect();
        }
    }
    
    private static URL validateUrl(String url) throws Exception {
        URL fileUrl = new URL(url);
        
        // 验证协议
        if (!fileUrl.getProtocol().equals("https")) {
            throw new SecurityException("Only HTTPS allowed");
        }
        
        // 验证域名
        if (!isAllowedDomain(fileUrl.getHost())) {
            throw new SecurityException("Domain not allowed");
        }
        
        return fileUrl;
    }
}
```

### 3. DNS 重绑定防护
```java
public class DNSRebindingProtection {
    private static final Cache<String, InetAddress> DNS_CACHE = 
        CacheBuilder.newBuilder()
            .expireAfterWrite(1, TimeUnit.HOURS)
            .build();
    
    public static boolean isValidHost(String host) throws Exception {
        // 获取缓存的 IP
        InetAddress cachedIP = DNS_CACHE.getIfPresent(host);
        
        // 解析当前 IP
        InetAddress currentIP = InetAddress.getByName(host);
        
        // 如果没有缓存，缓存当前结果
        if (cachedIP == null) {
            DNS_CACHE.put(host, currentIP);
            return isAllowedIP(currentIP);
        }
        
        // 比较 IP 是否变化
        if (!cachedIP.equals(currentIP)) {
            logger.warn("DNS Rebinding detected for host: " + host);
            return false;
        }
        
        return isAllowedIP(currentIP);
    }
    
    private static boolean isAllowedIP(InetAddress addr) {
        // IP 验证逻辑
        return true;
    }
}
```

## 修复建议

### 1. 代码层面
1. URL 验证：
   - 实现 URL 白名单
   - 验证协议类型
   - 验证域名合法性
   - 验证 IP 地址范围

2. 请求控制：
   - 禁止重定向
   - 设置超时时间
   - 限制请求大小
   - 验证响应类型

3. 安全防护：
   - 实现 DNS 缓存
   - 防止 DNS 重绑定
   - 禁止访问内网
   - 记录安全日志

### 2. 架构层面
1. 网络隔离：
   - 部署反向代理
   - 配置防火墙
   - 实现网络隔离
   - 限制访问范围

2. 监控告警：
   - 异常请求监控
   - DNS 解析监控
   - 资源使用监控
   - 实时告警通知

3. 安全加固：
   - 更新安全配置
   - 实施访问控制
   - 加强认证授权
   - 定期安全评估

## 风险评估
- 严重程度：高
- 利用难度：中
- 影响范围：全局
- 修复优先级：高

## 后续跟踪
- [ ] 修复不安全的 URL 请求
- [ ] 实现 URL 白名单
- [ ] 加强域名验证
- [ ] 实现 DNS 防护
- [ ] 改进错误处理
- [ ] 添加安全测试
- [ ] 更新安全基线
- [ ] 培训开发人员 