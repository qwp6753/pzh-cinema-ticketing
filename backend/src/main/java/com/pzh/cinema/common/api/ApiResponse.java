package com.pzh.cinema.common.api;

import org.slf4j.MDC;

public record ApiResponse<T>(int code, String message, T data, String requestId) {
    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(0, "成功", data, MDC.get("requestId"));
    }

    public static <T> ApiResponse<T> failure(ErrorCode error, T data) {
        return new ApiResponse<>(error.getCode(), error.getMessage(), data, MDC.get("requestId"));
    }
}
