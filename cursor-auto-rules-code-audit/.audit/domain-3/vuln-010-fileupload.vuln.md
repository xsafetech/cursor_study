---
version: 1.0.0
status: Draft
last_updated: 2024-02-20

# 文件上传漏洞审计报告

## 漏洞信息
- 漏洞ID: VULN-010
- 组件: FileUpload.java
- 风险等级: 高
- 影响范围: 文件上传功能

## 漏洞描述

### 1. 任意文件上传漏洞
**问题代码**：
```java
@PostMapping("/upload")
public String singleFileUpload(@RequestParam("file") MultipartFile file,
                               RedirectAttributes redirectAttributes) {
    if (file.isEmpty()) {
        redirectAttributes.addFlashAttribute("message", "Please select a file to upload");
        return "redirect:/file/status";
    }

    try {
        byte[] bytes = file.getBytes();
        Path path = Paths.get(UPLOADED_FOLDER + file.getOriginalFilename());
        Files.write(path, bytes);
        // ...
    } catch (IOException e) {
        // ...
    }
    return "redirect:/file/status";
}
```
- 直接使用原始文件名
- 未进行文件类型验证
- 未限制文件大小
- 存储路径固定且可预测

**影响**：
- 可以上传任意类型文件
- 可能导致代码执行
- 可能导致服务器被入侵
- 可能导致拒绝服务

### 2. 不完整的图片上传验证
**问题代码**：
```java
@PostMapping("/upload/picture")
@ResponseBody
public String uploadPicture(@RequestParam("file") MultipartFile multifile) throws Exception {
    String fileName = multifile.getOriginalFilename();
    String Suffix = fileName.substring(fileName.lastIndexOf(".")); // 获取文件后缀名
    String mimeType = multifile.getContentType(); // 获取MIME类型
    String filePath = UPLOADED_FOLDER + fileName;
    File excelFile = convert(multifile);

    // 判断文件后缀名是否在白名单内
    String[] picSuffixList = {".jpg", ".png", ".jpeg", ".gif", ".bmp", ".ico"};
    // ...

    // 判断MIME类型是否在黑名单内
    String[] mimeTypeBlackList = {
        "text/html",
        "text/javascript",
        "application/javascript",
        "application/ecmascript",
        "text/xml",
        "application/xml"
    };
    // ...

    // 判断文件内容是否是图片
    boolean isImageFlag = isImage(excelFile);
    // ...
}
```
- 文件后缀名检查可被绕过
- MIME 类型黑名单不完整
- 文件内容验证不充分
- 临时文件处理不当

**影响**：
1. 验证绕过：
   - 可以通过双后缀名绕过
   - 可以通过大小写绕过
   - 可以通过 MIME 类型绕过
   - 可以通过文件内容伪造绕过

2. 安全风险：
   - 可以上传恶意文件
   - 可以执行恶意代码
   - 可以进行 XSS 攻击
   - 可以进行钓鱼攻击

### 3. 不安全的文件处理
**问题代码**：
```java
private File convert(MultipartFile multiFile) throws Exception {
    String fileName = multiFile.getOriginalFilename();
    String suffix = fileName.substring(fileName.lastIndexOf("."));
    UUID uuid = Generators.timeBasedGenerator().generate();
    randomFilePath = UPLOADED_FOLDER + uuid + suffix;
    File convFile = new File(randomFilePath);
    boolean ret = convFile.createNewFile();
    if (!ret) {
        return null;
    }
    FileOutputStream fos = new FileOutputStream(convFile);
    fos.write(multiFile.getBytes());
    fos.close();
    return convFile;
}
```
- 文件路径拼接不安全
- 临时文件清理不完整
- 文件权限设置不当
- 错误处理不完善

## 安全实现示例

### 1. 安全的文件上传
```java
@PostMapping("/upload/safe")
public String uploadSafe(@RequestParam("file") MultipartFile file) throws IOException {
    // 验证文件是否为空
    if (file.isEmpty()) {
        throw new IllegalArgumentException("File is empty");
    }
    
    // 验证文件大小
    if (file.getSize() > MAX_FILE_SIZE) {
        throw new IllegalArgumentException("File too large");
    }
    
    // 获取安全的文件名
    String fileName = SecurityUtils.sanitizeFileName(
        file.getOriginalFilename()
    );
    
    // 验证文件类型
    if (!isAllowedFileType(fileName, file.getContentType())) {
        throw new IllegalArgumentException("Invalid file type");
    }
    
    // 生成安全的存储路径
    Path storagePath = generateStoragePath(fileName);
    
    // 保存文件
    try {
        Files.copy(
            file.getInputStream(),
            storagePath,
            StandardCopyOption.REPLACE_EXISTING
        );
        
        // 设置文件权限
        setSecureFilePermissions(storagePath);
        
        return "File uploaded successfully";
    } catch (IOException e) {
        throw new IOException("Failed to store file", e);
    }
}
```

### 2. 完整的文件验证
```java
public class FileValidator {
    // 允许的文件类型
    private static final Map<String, List<String>> ALLOWED_TYPES;
    static {
        ALLOWED_TYPES = new HashMap<>();
        ALLOWED_TYPES.put("image", Arrays.asList(
            "image/jpeg", "image/png", "image/gif"
        ));
        ALLOWED_TYPES.put("document", Arrays.asList(
            "application/pdf", "application/msword"
        ));
    }
    
    // 文件类型验证
    public static boolean isValidFileType(String fileName, String contentType) {
        // 验证文件后缀
        String extension = getFileExtension(fileName);
        if (!isValidExtension(extension)) {
            return false;
        }
        
        // 验证 MIME 类型
        if (!isValidMimeType(contentType)) {
            return false;
        }
        
        // 验证文件头
        return isValidFileHeader(file);
    }
    
    // 文件内容验证
    public static boolean isValidContent(Path filePath) {
        try {
            // 读取文件头
            byte[] header = readFileHeader(filePath);
            
            // 验证文件签名
            return isValidFileSignature(header);
            
        } catch (IOException e) {
            logger.error("Failed to validate file content", e);
            return false;
        }
    }
}
```

### 3. 安全的文件存储
```java
public class SecureFileStorage {
    private static final String STORAGE_ROOT = "/secure/storage/";
    
    public static Path store(MultipartFile file) throws IOException {
        // 生成唯一文件名
        String uniqueName = generateUniqueFileName(file);
        
        // 创建存储目录
        Path storageDir = createStorageDirectory();
        
        // 构建存储路径
        Path storagePath = storageDir.resolve(uniqueName);
        
        // 保存文件
        Files.copy(
            file.getInputStream(),
            storagePath,
            StandardCopyOption.REPLACE_EXISTING
        );
        
        // 设置权限
        setSecurePermissions(storagePath);
        
        return storagePath;
    }
    
    private static void setSecurePermissions(Path path) {
        // 设置文件所有者
        Files.setOwner(path, USER);
        
        // 设置文件权限
        Set<PosixFilePermission> perms = 
            EnumSet.of(OWNER_READ, OWNER_WRITE);
        Files.setPosixFilePermissions(path, perms);
    }
}
```

## 修复建议

### 1. 代码层面
1. 文件验证：
   - 实现完整的文件类型验证
   - 使用白名单验证
   - 验证文件内容
   - 限制文件大小

2. 文件存储：
   - 使用安全的文件名
   - 实现安全的存储路径
   - 设置适当的权限
   - 清理临时文件

3. 错误处理：
   - 实现统一异常处理
   - 记录详细日志
   - 返回安全的错误信息
   - 实现错误恢复

### 2. 架构层面
1. 存储架构：
   - 分离上传目录
   - 实现文件隔离
   - 配置访问控制
   - 实现备份机制

2. 安全控制：
   - 实现上传限制
   - 配置防病毒
   - 实现审计日志
   - 监控告警

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
- [ ] 修复任意文件上传
- [ ] 完善文件验证
- [ ] 加强存储安全
- [ ] 改进错误处理
- [ ] 实现访问控制
- [ ] 添加安全测试
- [ ] 更新安全基线
- [ ] 培训开发人员