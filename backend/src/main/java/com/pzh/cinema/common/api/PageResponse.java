package com.pzh.cinema.common.api;

import java.util.List;

public record PageResponse<T>(List<T> records, long total, long page, long pageSize, long pages) {
}
