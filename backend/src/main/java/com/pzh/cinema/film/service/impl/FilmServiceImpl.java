package com.pzh.cinema.film.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.pzh.cinema.common.api.PageQuery;
import com.pzh.cinema.common.api.PageResponse;
import com.pzh.cinema.film.mapper.FilmMapper;
import com.pzh.cinema.film.entity.FilmEntity;
import com.pzh.cinema.film.service.FilmService;
import com.pzh.cinema.film.vo.FilmSummaryVO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class FilmServiceImpl implements FilmService {
    private final FilmMapper filmMapper;

    @Override
    @Transactional(readOnly = true)
    public PageResponse<FilmSummaryVO> pagePublished(PageQuery query) {
        // 列名为物理表核验后的固定值，不接收客户端提供的排序/SQL 片段。
        var filter = new QueryWrapper<FilmEntity>()
                .select("id", "film_name", "poster_url", "director", "country", "language",
                        "duration_minutes", "release_date", "release_status", "heat_score")
                .eq("publish_status", "PUBLISHED")
                .orderByDesc("id");
        var page = filmMapper.selectPage(new Page<FilmEntity>(query.getPage(), query.getPageSize()), filter);
        var records = page.getRecords().stream().map(film -> new FilmSummaryVO(film.getId(), film.getFilmName(),
                film.getPosterUrl(), film.getDirector(), film.getCountry(), film.getLanguage(),
                film.getDurationMinutes(), film.getReleaseDate(), film.getReleaseStatus(), film.getHeatScore())).toList();
        return new PageResponse<>(records, page.getTotal(), page.getCurrent(), page.getSize(), page.getPages());
    }
}
