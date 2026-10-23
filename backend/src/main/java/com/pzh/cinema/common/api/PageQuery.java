package com.pzh.cinema.common.api;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PageQuery {
    @NotNull @Min(1) @Max(1_000_000)
    @Schema(description = "页码，从 1 开始，最大 1000000", defaultValue = "1")
    private Long page = 1L;
    @NotNull @Min(1) @Max(100)
    @Schema(description = "每页条数，范围 1..100", defaultValue = "10")
    private Long pageSize = 10L;
}
