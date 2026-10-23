package com.pzh.cinema.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {
    @Bean
    public OpenAPI cinemaOpenApi() {
        return new OpenAPI().info(new Info().title("攀枝花市影院售票系统 API")
                .version("0.1.0").description("后端基础阶段：真实影片分页查询。尚未提供登录与令牌签发。"));
    }
}
