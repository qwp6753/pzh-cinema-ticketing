package com.pzh.cinema.film;

import com.baomidou.mybatisplus.core.conditions.Wrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.pzh.cinema.common.api.PageQuery;
import com.pzh.cinema.film.entity.FilmEntity;
import com.pzh.cinema.film.mapper.FilmMapper;
import com.pzh.cinema.film.service.impl.FilmServiceImpl;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class FilmServiceTest {
    @Test
    @SuppressWarnings({"unchecked", "rawtypes"})
    void paginatesPublishedFilmsAndMapsPublicFields() {
        FilmMapper mapper = mock(FilmMapper.class);
        var film = new FilmEntity();
        film.setId(12L); film.setFilmName("测试影片"); film.setOriginalName(null);
        film.setPosterUrl(null); film.setTrailerUrl(null); film.setDirector("测试导演");
        film.setCastList("[\"演员\"]"); film.setCountry("中国"); film.setLanguage("普通话");
        film.setDurationMinutes(120); film.setReleaseDate(LocalDate.of(2026, 1, 1));
        film.setSynopsis("简介"); film.setReleaseStatus("SHOWING"); film.setPublishStatus("PUBLISHED");
        film.setHeatScore(60L); film.setCreatedAt(LocalDateTime.of(2026,1,1,0,0));
        film.setUpdatedAt(LocalDateTime.of(2026,1,1,0,0));
        when(mapper.selectPage(any(Page.class), any(Wrapper.class))).thenAnswer(invocation -> {
            Page<FilmEntity> page = invocation.getArgument(0);
            page.setTotal(21); page.setRecords(List.of(film));
            return page;
        });
        var query = new PageQuery(); query.setPage(2L); query.setPageSize(10L);
        var result = new FilmServiceImpl(mapper).pagePublished(query);
        assertThat(result.page()).isEqualTo(2);
        assertThat(result.pageSize()).isEqualTo(10);
        assertThat(result.total()).isEqualTo(21);
        assertThat(result.pages()).isEqualTo(3);
        assertThat(result.records()).hasSize(1);
        assertThat(result.records().getFirst().id()).isEqualTo(12L);
        assertThat(result.records().getFirst().filmName()).isEqualTo("测试影片");
        ArgumentCaptor<Wrapper<FilmEntity>> filter = ArgumentCaptor.forClass(Wrapper.class);
        verify(mapper).selectPage(any(Page.class), filter.capture());
        assertThat(filter.getValue().getSqlSegment()).contains("publish_status =", "ORDER BY id DESC");
        assertThat(((com.baomidou.mybatisplus.core.conditions.AbstractWrapper) filter.getValue())
                .getParamNameValuePairs()).containsValue("PUBLISHED");
    }
}
