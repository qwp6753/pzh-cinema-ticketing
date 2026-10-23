package com.pzh.cinema.common.api;

import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

@Getter
@RequiredArgsConstructor
public enum ErrorCode {
    BAD_REQUEST(40000, "请求参数不合法", HttpStatus.BAD_REQUEST),
    UNAUTHORIZED(40100, "请先登录", HttpStatus.UNAUTHORIZED),
    FORBIDDEN(40300, "没有访问权限", HttpStatus.FORBIDDEN),
    NOT_FOUND(40400, "资源不存在", HttpStatus.NOT_FOUND),
    METHOD_NOT_ALLOWED(40500, "请求方法不支持", HttpStatus.METHOD_NOT_ALLOWED),
    CONFLICT(40900, "操作与当前状态冲突", HttpStatus.CONFLICT),
    INTERNAL_ERROR(50000, "服务器暂时无法处理请求", HttpStatus.INTERNAL_SERVER_ERROR),
    DEPENDENCY_UNAVAILABLE(50300, "依赖服务暂时不可用", HttpStatus.SERVICE_UNAVAILABLE);

    private final int code;
    private final String message;
    private final HttpStatus status;
}
