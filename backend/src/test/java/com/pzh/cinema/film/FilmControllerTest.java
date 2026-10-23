package com.pzh.cinema.film;

import com.pzh.cinema.common.api.ErrorCode;
import com.pzh.cinema.common.api.PageQuery;
import com.pzh.cinema.common.api.PageResponse;
import com.pzh.cinema.common.exception.BusinessException;
import com.pzh.cinema.common.web.RequestIdFilter;
import com.pzh.cinema.config.SecurityConfig;
import com.pzh.cinema.film.controller.FilmController;
import com.pzh.cinema.film.service.FilmService;
import com.pzh.cinema.film.vo.FilmSummaryVO;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import java.time.LocalDate;
import java.util.List;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(FilmController.class)
@Import({SecurityConfig.class, RequestIdFilter.class})
@ActiveProfiles("dev")
class FilmControllerTest {
    @Autowired MockMvc mvc;
    @MockitoBean FilmService filmService;

    @Test
    void defaultPaginationReturnsEnvelopeAndLosslessId() throws Exception {
        when(filmService.pagePublished(any())).thenAnswer(invocation -> {
            PageQuery query = invocation.getArgument(0);
            return new PageResponse<>(List.of(new FilmSummaryVO(9007199254740993L, "测试影片", null,
                    "导演", "中国", "普通话", 120, LocalDate.of(2026, 1, 1), "SHOWING", 100L)),
                    1, query.getPage(), query.getPageSize(), 1);
        });
        mvc.perform(get("/api/v1/films").header("X-Request-Id", "test-default"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.page").value(1)).andExpect(jsonPath("$.data.pageSize").value(10))
                .andExpect(jsonPath("$.data.records[0].id").value("9007199254740993"))
                .andExpect(jsonPath("$.requestId").value("test-default"))
                .andExpect(header().string("X-Request-Id", "test-default"));
        assertThat(MDC.get("requestId")).isNull();
    }

    @ParameterizedTest
    @CsvSource({"page,0", "page,-1", "page,1000001", "pageSize,0", "pageSize,101", "page,abc", "pageSize,9999999999999999999999"})
    void rejectsInvalidPagination(String field, String value) throws Exception {
        mvc.perform(get("/api/v1/films").param(field, value)).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(40000)).andExpect(jsonPath("$.data[0].field").value(field));
    }

    @ParameterizedTest
    @CsvSource({"page[0]", "pageSize[0]"})
    void rejectsIndexedBindingToScalarPaginationWithBadRequest(String field) throws Exception {
        mvc.perform(get("/api/v1/films").param(field, "1"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value(40000));
    }

    @Test
    void businessFailuresUseTheirHttpStatus() throws Exception {
        when(filmService.pagePublished(any())).thenThrow(new BusinessException(ErrorCode.CONFLICT));
        mvc.perform(get("/api/v1/films")).andExpect(status().isConflict()).andExpect(jsonPath("$.code").value(40900));
    }

    @Test
    void databaseFailureDoesNotRevealSqlOrCredentials() throws Exception {
        when(filmService.pagePublished(any())).thenThrow(new DataAccessResourceFailureException("private SQL secret-fixture"));
        mvc.perform(get("/api/v1/films")).andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.code").value(50300)).andExpect(content().string(not(containsString("secret-fixture"))));
    }

    @Test
    void unknownFailureDoesNotRevealInternalDetails() throws Exception {
        when(filmService.pagePublished(any())).thenThrow(new IllegalStateException("internal-fixture"));
        mvc.perform(get("/api/v1/films")).andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.code").value(50000)).andExpect(content().string(not(containsString("internal-fixture"))));
    }

    @Test
    void accessDeniedExceptionReturnsForbiddenEnvelope() throws Exception {
        when(filmService.pagePublished(any())).thenThrow(new AccessDeniedException("private reason"));
        mvc.perform(get("/api/v1/films")).andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value(40300));
    }

    @Test
    void protectsOtherBusinessRoutesAndFilmWrites() throws Exception {
        mvc.perform(get("/api/v1/admin/users")).andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value(40100));
        mvc.perform(post("/api/v1/films")).andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value(40100));
    }

    @Test
    void allowsConfiguredCorsPreflight() throws Exception {
        mvc.perform(options("/api/v1/films").header("Origin", "http://localhost:5173")
                        .header("Access-Control-Request-Method", "GET").header("Access-Control-Request-Headers", "X-Request-Id"))
                .andExpect(status().isOk()).andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:5173"));
    }

    @Test
    void rejectsUnconfiguredCorsOrigin() throws Exception {
        mvc.perform(options("/api/v1/films").header("Origin", "https://untrusted.example")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isForbidden()).andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
    }

    @Test
    void invalidSuppliedRequestIdIsReplaced() throws Exception {
        var result = mvc.perform(get("/api/v1/admin/users").header("X-Request-Id", "invalid spaces"))
                .andExpect(status().isUnauthorized()).andReturn();
        assertThat(result.getResponse().getHeader("X-Request-Id")).matches("[a-f0-9-]{36}");
        assertThat(MDC.get("requestId")).isNull();
    }
}
