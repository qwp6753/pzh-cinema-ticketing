package com.pzh.cinema.film.controller;

import com.pzh.cinema.common.api.ApiResponse;
import com.pzh.cinema.common.api.PageQuery;
import com.pzh.cinema.common.api.PageResponse;
import com.pzh.cinema.film.service.FilmService;
import com.pzh.cinema.film.vo.FilmSummaryVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/films")
@RequiredArgsConstructor
@Tag(name = "影片查询")
public class FilmController {
    private final FilmService filmService;

    @GetMapping
    @Operation(summary = "分页查询已发布影片", description = "按影片 id 倒序；页码从 1 开始；越界页返回空记录。")
    public ApiResponse<PageResponse<FilmSummaryVO>> page(@Valid @ModelAttribute @ParameterObject PageQuery query) {
        return ApiResponse.success(filmService.pagePublished(query));
    }
}
