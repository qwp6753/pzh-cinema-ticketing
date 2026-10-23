package com.pzh.cinema;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.security.servlet.UserDetailsServiceAutoConfiguration;

// 本阶段不生成默认账号/密码；后续由 JWT 和 RBAC 模块接管认证。
@SpringBootApplication(exclude = UserDetailsServiceAutoConfiguration.class)
public class CinemaApplication {
    public static void main(String[] args) {
        SpringApplication.run(CinemaApplication.class, args);
    }
}
