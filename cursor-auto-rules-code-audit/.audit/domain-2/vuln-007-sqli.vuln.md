---
version: 1.0.0
status: Draft
last_updated: 2024-02-20

# SQL 注入漏洞审计报告

## 漏洞信息
- 漏洞ID: VULN-007
- 组件: SQLI.java, UserMapper.xml
- 风险等级: 高
- 影响范围: 数据库访问层

## 漏洞描述

### 1. JDBC SQL 注入漏洞
**问题代码**：
```java
String sql = "select * from users where username = '" + username + "'";
Statement statement = con.createStatement();
ResultSet rs = statement.executeQuery(sql);
```
- 直接字符串拼接构造 SQL 语句
- 未对输入参数进行验证和过滤
- 使用 Statement 而不是 PreparedStatement
- 错误处理不完整

**影响**：
- 可以通过注入执行任意 SQL 命令
- 可能导致数据泄露
- 可能导致数据被篡改
- 可能导致数据库被破坏

### 2. PreparedStatement 使用不当
**问题代码**：
```java
String sql = "select * from users where username = '" + username + "'";
PreparedStatement st = con.prepareStatement(sql);
```
- 虽然使用了 PreparedStatement，但仍然进行字符串拼接
- 未使用参数占位符 ?
- PreparedStatement 的安全特性被绕过
- 实际上与使用 Statement 无异

### 3. MyBatis XML 映射文件中的 SQL 注入
**问题代码**：
```xml
<select id="findByUserNameVuln02" parameterType="String" resultMap="User">
    select * from users where username like '%${_parameter}%'
</select>

<select id="findByUserNameVuln03" parameterType="String" resultMap="User">
    select * from users
    <if test="order != null">
        order by ${order} asc
    </if>
</select>
```
- 使用 ${} 而不是 #{} 进行参数替换
- 在 LIKE 语句中直接拼接参数
- ORDER BY 子句中的参数注入
- 缺少参数验证和过滤

**影响**：
1. LIKE 语句注入：
   - 可以通过闭合引号注入任意条件
   - 可以绕过 LIKE 查询限制
   - 可以执行 UNION 查询
   - 可以进行数据库枚举

2. ORDER BY 注入：
   - 可以注入任意排序条件
   - 可以执行子查询
   - 可以进行信息泄露
   - 可以进行数据库探测

## 安全实现示例

### 1. JDBC 安全实现
```java
String sql = "select * from users where username = ?";
PreparedStatement st = con.prepareStatement(sql);
st.setString(1, username);
```
- 使用参数占位符
- 使用 PreparedStatement
- 正确的参数绑定
- 完整的错误处理

### 2. MyBatis XML 安全实现
```xml
<select id="findByUserName" resultMap="User">
    select * from users where username = #{username}
</select>

<select id="findById" resultMap="User">
    select * from users where id = #{id}
</select>

<select id="OrderByUsername" resultMap="User">
    select * from users order by id asc limit 1
</select>
```
- 使用 #{} 进行参数绑定
- 固定的 ORDER BY 语句
- 类型安全的参数处理
- 避免动态 SQL 拼接

### 3. 安全的动态 SQL
```xml
<select id="findByUserNameSafe" parameterType="String" resultMap="User">
    select * from users where 1=1
    <if test="username != null">
        AND username LIKE CONCAT('%', #{username}, '%')
    </if>
    <if test="orderBy != null">
        <choose>
            <when test="orderBy == 'id'">ORDER BY id</when>
            <when test="orderBy == 'username'">ORDER BY username</when>
            <otherwise>ORDER BY id</otherwise>
        </choose>
    </if>
</select>
```
- 使用 CONCAT 函数处理 LIKE
- 使用 #{} 参数绑定
- 白名单验证排序字段
- 默认安全排序

## 修复建议

### 1. 代码层面
1. 参数化查询：
   - 使用 PreparedStatement
   - 使用参数占位符
   - 避免字符串拼接
   - 实现参数验证

2. MyBatis 配置：
   - 使用 #{} 进行参数绑定
   - 避免使用 ${}
   - 实现类型处理器
   - 配置 SQL 注入器

3. 错误处理：
   - 实现统一异常处理
   - 避免暴露错误细节
   - 记录详细日志
   - 实现错误恢复

### 2. 架构层面
1. 数据访问层：
   - 使用 ORM 框架
   - 实现 DAO 模式
   - 统一数据访问
   - 集中式配置

2. 安全控制：
   - 实现输入验证
   - 实现访问控制
   - 实现审计日志
   - 实现监控告警

3. 配置管理：
   - 使用配置中心
   - 实现版本控制
   - 环境隔离
   - 密钥管理

## 风险评估
- 严重程度：高
- 利用难度：低
- 影响范围：全局
- 修复优先级：高

## 后续跟踪
- [ ] 修复 JDBC SQL 注入
- [ ] 修复 PreparedStatement 使用不当
- [ ] 修复 MyBatis XML 中的 SQL 注入
- [ ] 实现输入验证
- [ ] 改进错误处理
- [ ] 添加安全测试
- [ ] 更新开发规范
- [ ] 培训开发人员 