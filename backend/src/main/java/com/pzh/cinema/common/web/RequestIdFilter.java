package com.pzh.cinema.common.web;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.UUID;

@Slf4j
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class RequestIdFilter extends OncePerRequestFilter {
    public static final String HEADER = "X-Request-Id";

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        var supplied = request.getHeader(HEADER);
        var requestId = supplied != null && supplied.matches("[A-Za-z0-9._-]{1,64}")
                ? supplied : UUID.randomUUID().toString();
        long start = System.nanoTime();
        MDC.put("requestId", requestId);
        response.setHeader(HEADER, requestId);
        try {
            chain.doFilter(request, response);
        } finally {
            // 不记录查询串、请求体或 Authorization，避免未来地图密钥、令牌等进入日志。
            log.info("{} {} status={} elapsedMs={}", request.getMethod(), request.getRequestURI(),
                    response.getStatus(), (System.nanoTime() - start) / 1_000_000);
            MDC.remove("requestId");
        }
    }
}
