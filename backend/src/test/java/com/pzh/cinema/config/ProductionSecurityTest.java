package com.pzh.cinema.config;

import com.pzh.cinema.film.controller.FilmController;
import com.pzh.cinema.film.service.FilmService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(FilmController.class)
@Import(SecurityConfig.class)
@ActiveProfiles("prod")
class ProductionSecurityTest {
    @Autowired MockMvc mvc;
    @MockitoBean FilmService filmService;

    @Test
    void docsAreNotPublicInProduction() throws Exception {
        mvc.perform(get("/v3/api-docs")).andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value(40100));
        mvc.perform(get("/swagger-ui/index.html")).andExpect(status().isUnauthorized());
    }

    @Test
    void noCorsOriginIsAllowedWithoutProductionConfiguration() throws Exception {
        mvc.perform(options("/api/v1/films").header("Origin", "http://localhost:5173")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isForbidden());
    }
}
