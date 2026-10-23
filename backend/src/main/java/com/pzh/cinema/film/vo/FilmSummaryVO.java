package com.pzh.cinema.film.vo;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;

public record FilmSummaryVO(
        @Schema(type = "string", description = "BIGINT 主键，以字符串返回避免 JS 精度丢失")
        @JsonSerialize(using = ToStringSerializer.class) Long id,
        String filmName, String posterUrl, String director, String country, String language,
        Integer durationMinutes, LocalDate releaseDate, String releaseStatus, Long heatScore) {
}
