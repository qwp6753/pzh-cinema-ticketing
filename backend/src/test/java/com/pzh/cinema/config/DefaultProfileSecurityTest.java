package com.pzh.cinema.config;

import com.pzh.cinema.film.controller.FilmController;
import com.pzh.cinema.film.service.FilmService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(FilmController.class)
@Import(SecurityConfig.class)
class DefaultProfileSecurityTest {
    @Autowired MockMvc mvc;
    @MockitoBean FilmService filmService;

    @Test
    void defaultDevelopmentProfileDoesNotBlockDocumentRoutes() throws Exception {
        // MVC 切片不注册 Springdoc；404 表示已通过安全过滤，401 表示误拦截。
        mvc.perform(get("/v3/api-docs")).andExpect(status().isNotFound());
    }
}
