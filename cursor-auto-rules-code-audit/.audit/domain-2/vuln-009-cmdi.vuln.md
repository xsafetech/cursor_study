---
version: 1.0.0
status: Draft
last_updated: 2024-02-20

# 命令注入漏洞审计报告

## 漏洞信息
- 漏洞ID: VULN-009
- 组件: CommandInject.java
- 风险等级: 高
- 影响范围: 系统命令执行

## 漏洞描述

### 1. 文件路径命令注入
**问题代码**：
```java
@GetMapping("/codeinject")
public String codeInject(String filepath) throws IOException {
    String[] cmdList = new String[]{"sh", "-c", "ls -la " + filepath};
    ProcessBuilder builder = new ProcessBuilder(cmdList);
    builder.redirectErrorStream(true);
    Process process = builder.start();
    return WebUtils.convertStreamToString(process.getInputStream());
}
```
- 直接拼接用户输入到命令字符串
- 未对输入参数进行验证
- 使用 shell 命令解释器
- 错误处理不完整

**影响**：
- 可以执行任意系统命令
- 可能导致系统被入侵
- 可能导致数据泄露
- 可能导致服务器被控制

### 2. Host 头命令注入
**问题代码**：
```java
@GetMapping("/codeinject/host")
public String codeInjectHost(HttpServletRequest request) throws IOException {
    String host = request.getHeader("host");
    logger.info(host);
    String[] cmdList = new String[]{"sh", "-c", "curl " + host};
    ProcessBuilder builder = new ProcessBuilder(cmdList);
    builder.redirectErrorStream(true);
    Process process = builder.start();
    return WebUtils.convertStreamToString(process.getInputStream());
}
```
- 直接使用 HTTP Host 头
- 未对 Host 头进行验证
- 命令字符串拼接
- 可能被用于服务器端请求伪造

**影响**：
1. 命令注入：
   - 可以执行任意命令
   - 可以访问内部资源
   - 可以进行横向移动
   - 可以持久化后门

2. SSRF 风险：
   - 可以访问内网服务
   - 可以探测内网
   - 可以绕过防火墙
   - 可以进行内网攻击

### 3. 不完整的命令注入防护
**问题代码**：
```java
@GetMapping("/codeinject/sec")
public String codeInjectSec(String filepath) throws IOException {
    String filterFilePath = SecurityUtil.cmdFilter(filepath);
    if (null == filterFilePath) {
        return "Bad boy. I got u.";
    }
    String[] cmdList = new String[]{"sh", "-c", "ls -la " + filterFilePath};
    ProcessBuilder builder = new ProcessBuilder(cmdList);
    builder.redirectErrorStream(true);
    Process process = builder.start();
    return WebUtils.convertStreamToString(process.getInputStream());
}
```
- 过滤实现不完整
- 仍然使用命令解释器
- 错误处理不完善
- 日志记录不充分

## 安全实现示例

### 1. 安全的文件操作
```java
@GetMapping("/file/safe")
public String fileSafe(String filepath) throws IOException {
    // 输入验证
    if (!isValidFilePath(filepath)) {
        throw new IllegalArgumentException("Invalid file path");
    }
    
    // 使用 Java API 而不是系统命令
    Path path = Paths.get(filepath);
    if (!Files.exists(path)) {
        throw new FileNotFoundException("File not found");
    }
    
    // 安全的文件属性获取
    BasicFileAttributes attrs = Files.readAttributes(
        path, 
        BasicFileAttributes.class
    );
    
    // 构建安全的响应
    return FileUtils.buildFileInfo(path, attrs);
}

private boolean isValidFilePath(String filepath) {
    if (filepath == null || filepath.trim().isEmpty()) {
        return false;
    }
    
    // 路径规范化
    Path path = Paths.get(filepath).normalize();
    
    // 检查是否在允许的目录下
    return path.startsWith(ALLOWED_BASE_DIR) && 
           !path.toString().contains("..") &&
           ALLOWED_FILE_PATTERN.matcher(path.toString()).matches();
}
```

### 2. 安全的 HTTP 请求
```java
@GetMapping("/http/safe")
public String httpSafe(HttpServletRequest request) throws IOException {
    String host = request.getHeader("host");
    
    // 输入验证
    if (!isValidHost(host)) {
        throw new IllegalArgumentException("Invalid host");
    }
    
    // 使用 HTTP 客户端库
    HttpClient client = HttpClients.custom()
        .setDefaultRequestConfig(RequestConfig.custom()
            .setConnectTimeout(5000)
            .setSocketTimeout(5000)
            .build())
        .build();
        
    HttpGet httpGet = new HttpGet("http://" + host);
    
    // 执行请求
    try (CloseableHttpResponse response = client.execute(httpGet)) {
        return EntityUtils.toString(response.getEntity());
    }
}

private boolean isValidHost(String host) {
    if (host == null || host.trim().isEmpty()) {
        return false;
    }
    
    // 域名格式验证
    if (!DOMAIN_PATTERN.matcher(host).matches()) {
        return false;
    }
    
    // 检查是否在白名单中
    return ALLOWED_HOSTS.contains(host);
}
```

### 3. 完整的命令执行防护
```java
public class CommandExecutor {
    private static final Logger logger = LoggerFactory.getLogger(CommandExecutor.class);
    
    // 预定义的安全命令
    private static final Map<String, String[]> SAFE_COMMANDS;
    static {
        SAFE_COMMANDS = new HashMap<>();
        SAFE_COMMANDS.put("list", new String[]{"ls", "-l"});
        SAFE_COMMANDS.put("disk", new String[]{"df", "-h"});
        // ... 其他安全命令
    }
    
    public static String executeCommand(String commandKey, String... args) {
        // 检查命令是否在白名单中
        String[] baseCommand = SAFE_COMMANDS.get(commandKey);
        if (baseCommand == null) {
            throw new SecurityException("Command not allowed");
        }
        
        // 验证参数
        for (String arg : args) {
            if (!isValidArgument(arg)) {
                throw new IllegalArgumentException("Invalid argument");
            }
        }
        
        // 构建完整命令
        String[] fullCommand = new String[baseCommand.length + args.length];
        System.arraycopy(baseCommand, 0, fullCommand, 0, baseCommand.length);
        System.arraycopy(args, 0, fullCommand, baseCommand.length, args.length);
        
        try {
            // 执行命令
            ProcessBuilder pb = new ProcessBuilder(fullCommand);
            pb.redirectErrorStream(true);
            
            // 设置工作目录
            pb.directory(new File(SAFE_WORK_DIR));
            
            // 设置环境变量
            Map<String, String> env = pb.environment();
            env.clear();
            env.put("PATH", SAFE_PATH);
            
            // 执行并获取结果
            Process p = pb.start();
            String output = IOUtils.toString(p.getInputStream(), StandardCharsets.UTF_8);
            
            // 等待完成
            if (p.waitFor(10, TimeUnit.SECONDS)) {
                return output;
            } else {
                p.destroyForcibly();
                throw new TimeoutException("Command execution timed out");
            }
        } catch (Exception e) {
            logger.error("Command execution failed", e);
            throw new RuntimeException("Command execution failed", e);
        }
    }
}
```

## 修复建议

### 1. 代码层面
1. 命令执行：
   - 避免使用系统命令
   - 使用 Java API
   - 实现命令白名单
   - 参数严格验证

2. 输入验证：
   - 实现白名单验证
   - 规范化输入
   - 类型检查
   - 长度限制

3. 错误处理：
   - 统一异常处理
   - 安全的错误消息
   - 完整的日志记录
   - 超时控制

### 2. 架构层面
1. 安全架构：
   - 最小权限原则
   - 环境隔离
   - 访问控制
   - 审计日志

2. 配置管理：
   - 安全基线配置
   - 环境变量控制
   - 文件权限控制
   - 网络访问控制

3. 运行时防护：
   - 进程隔离
   - 资源限制
   - 监控告警
   - 应急响应

## 风险评估
- 严重程度：高
- 利用难度：低
- 影响范围：全局
- 修复优先级：高

## 后续跟踪
- [ ] 修复文件路径命令注入
- [ ] 修复 Host 头命令注入
- [ ] 完善命令执行防护
- [ ] 实现输入验证
- [ ] 改进错误处理
- [ ] 加强日志记录
- [ ] 添加安全测试
- [ ] 更新安全基线 