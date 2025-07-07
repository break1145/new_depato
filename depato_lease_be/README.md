## 后端启动流程

1. ```bash
   git clone https://github.com/break1145/depato_lease_be.git
   cd depato_lease_be
   ```

2. 打开 idea，更新 maven 仓库，直接运行默认启动类[AdminWebApplication](web/web-admin/src/main/java/com/atguigu/lease/AdminWebApplication.java)
3. MySQL, Redis 已配置好云服务器，开箱即用
4. 启动后访问`http://localhost:8080/doc.html`查看 api 文档

## 找功能在[controller 文件夹](web/web-admin/src/main/java/com/atguigu/lease/web/admin/controller)
