---
version: 1.0.0
status: Draft
last_updated: 2024-02-20

# 路径遍历漏洞审计报告

## 漏洞信息
- 漏洞ID: VULN-011
- 组件: PathTraversal.java
- 风险等级: 高
- 影响范围: 文件访问功能

## 漏洞描述

### 1. 路径遍历漏洞
**问题代码**：
```java
@GetMapping("/path_traversal/vul")
public String getImage(String filepath) throws IOException {
    return getImgBase64(filepath);
}

private String getImgBase64(String imgFile) throws IOException {
    logger.info("Working directory: " + System.getProperty("user.dir"));
    logger.info("File path: " + imgFile);

    File f = new File(imgFile);
    if (f.exists() && !f.isDirectory()) {
        byte[] data = Files.readAllBytes(Paths.get(imgFile));
        return new String(Base64.encodeBase64(data));
    } else {
        return "File doesn't exist or is not a file.";
    }
}
```
- 直接使用用户输入的文件路径
- 未进行路径验证和规范化
- 未限制访问目录范围
- 错误处理不完整

**影响**：
- 可以访问任意系统文件
- 可能导致敏感信息泄露
- 可能导致系统配置泄露
- 可能导致系统被入侵

### 2. 不完整的路径过滤
**问题代码**：
```java
@GetMapping("/path_traversal/sec")
public String getImageSec(String filepath) throws IOException {
    if (SecurityUtil.pathFilter(filepath) == null) {
        logger.info("Illegal file path: " + filepath);
        return "Bad boy. Illegal file path.";
    }
    return getImgBase64(filepath);
}
```
- 路径过滤可能不完整
- 未处理符号链接
- 未验证文件类型
- 错误信息可能泄露信息

**影响**：
1. 过滤绕过：
   - 可以使用编码绕过
   - 可以使用符号链接绕过
   - 可以使用特殊字符绕过
   - 可以使用大小写绕过

2. 安全风险：
   - 可以访问系统文件
   - 可以读取配置文件
   - 可以获取敏感信息
   - 可以进行权限提升

### 3. 不安全的文件操作
**问题代码**：
```java
private String getImgBase64(String imgFile) throws IOException {
    File f = new File(imgFile);
    if (f.exists() && !f.isDirectory()) {
        byte[] data = Files.readAllBytes(Paths.get(imgFile));
        return new String(Base64.encodeBase64(data));
    }
    return "File doesn't exist or is not a file.";
}
```
- 文件操作不安全
- 未限制文件大小
- 未验证文件权限
- 资源释放不完整

## 安全实现示例

### 1. 安全的文件访问
```java
@GetMapping("/file/safe")
public String accessFileSafe(String filename) throws IOException {
    // 验证文件名
    if (!isValidFileName(filename)) {
        throw new IllegalArgumentException("Invalid filename");
    }
    
    // 构建安全的文件路径
    Path basePath = Paths.get(SAFE_FILE_ROOT).normalize();
    Path filePath = basePath.resolve(filename).normalize();
    
    // 验证路径
    if (!filePath.startsWith(basePath)) {
        throw new SecurityException("Path traversal attempt");
    }
    
    // 验证文件类型
    if (!isAllowedFileType(filePath)) {
        throw new SecurityException("Invalid file type");
    }
    
    // 验证文件权限
    if (!hasFileAccess(filePath)) {
        throw new SecurityException("Access denied");
    }
    
    // 安全地读取文件
    try {
        byte[] data = Files.readAllBytes(filePath);
        return Base64.getEncoder().encodeToString(data);
    } catch (IOException e) {
        logger.error("Failed to read file: " + e.getMessage());
        throw new IOException("File access error");
    }
}

private boolean isValidFileName(String filename) {
    return filename != null &&
           !filename.isEmpty() &&
           filename.matches("[a-zA-Z0-9._-]+") &&
           !filename.contains("..") &&
           !filename.startsWith(".") &&
           !filename.startsWith("/");
}
```

### 2. 完整的路径验证
```java
public class PathValidator {
    private static final String SAFE_ROOT = "/safe/files/";
    private static final Pattern SAFE_PATTERN = Pattern.compile(
        "^[a-zA-Z0-9][a-zA-Z0-9._-]*$"
    );
    
    public static Path validatePath(String input) throws SecurityException {
        // 基本验证
        if (input == null || input.trim().isEmpty()) {
            throw new SecurityException("Empty path");
        }
        
        // 文件名验证
        String filename = Paths.get(input).getFileName().toString();
        if (!SAFE_PATTERN.matcher(filename).matches()) {
            throw new SecurityException("Invalid filename");
        }
        
        try {
            // 规范化路径
            Path basePath = Paths.get(SAFE_ROOT).normalize();
            Path resolvedPath = basePath.resolve(filename).normalize();
            
            // 验证最终路径
            if (!resolvedPath.startsWith(basePath)) {
                throw new SecurityException("Path traversal detected");
            }
            
            // 验证符号链接
            if (Files.isSymbolicLink(resolvedPath)) {
                Path realPath = resolvedPath.toRealPath();
                if (!realPath.startsWith(basePath)) {
                    throw new SecurityException("Symlink attack detected");
                }
            }
            
            return resolvedPath;
            
        } catch (IOException e) {
            throw new SecurityException("Path validation error", e);
        }
    }
}
```

### 3. 安全的文件读取
```java
public class SecureFileReader {
    private static final int MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
    
    public static byte[] readFile(Path path) throws IOException {
        // 验证文件大小
        if (Files.size(path) > MAX_FILE_SIZE) {
            throw new SecurityException("File too large");
        }
        
        // 验证文件权限
        if (!Files.isReadable(path)) {
            throw new SecurityException("File not readable");
        }
        
        // 验证文件类型
        String mimeType = Files.probeContentType(path);
        if (!isAllowedMimeType(mimeType)) {
            throw new SecurityException("Invalid file type");
        }
        
        // 安全地读取文件
        try (InputStream in = Files.newInputStream(path)) {
            return readAllBytes(in);
        }
    }
    
    private static byte[] readAllBytes(InputStream in) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] buffer = new byte[8192];
        int read;
        
        while ((read = in.read(buffer)) != -1) {
            out.write(buffer, 0, read);
            
            // 检查大小限制
            if (out.size() > MAX_FILE_SIZE) {
                throw new SecurityException("File too large");
            }
        }
        
        return out.toByteArray();
    }
}
```

## 修复建议

### 1. 代码层面
1. 路径验证：
   - 实现路径规范化
   - 验证文件名格式
   - 限制访问范围
   - 处理符号链接

2. 文件操作：
   - 限制文件大小
   - 验证文件类型
   - 检查文件权限
   - 安全地读取文件

3. 错误处理：
   - 统一异常处理
   - 安全的错误消息
   - 完整的日志记录
   - 资源释放保证

### 2. 架构层面
1. 访问控制：
   - 实现文件隔离
   - 配置访问权限
   - 实现审计日志
   - 监控异常访问

2. 安全配置：
   - 限制文件类型
   - 配置安全目录
   - 设置文件权限
   - 实现访问控制

3. 运行时防护：
   - 文件系统隔离
   - 进程权限控制
   - 资源限制
   - 实时监控

## 风险评估
- 严重程度：高
- 利用难度：低
- 影响范围：全局
- 修复优先级：高

## 后续跟踪
- [ ] 修复路径遍历漏洞
- [ ] 完善路径验证
- [ ] 加强文件操作安全
- [ ] 改进错误处理
- [ ] 实现访问控制
- [ ] 添加安全测试
- [ ] 更新安全基线
- [ ] 培训开发人员 