package com.pzh.cinema.film.service;

import com.pzh.cinema.common.api.PageQuery;
import com.pzh.cinema.common.api.PageResponse;
import com.pzh.cinema.film.vo.FilmSummaryVO;

public interface FilmService {
    PageResponse<FilmSummaryVO> pagePublished(PageQuery query);
}
