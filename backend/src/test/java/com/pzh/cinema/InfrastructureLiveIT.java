package com.pzh.cinema;

import com.pzh.cinema.film.mapper.FilmMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.actuate.health.HealthEndpoint;
import org.springframework.boot.actuate.health.Status;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import java.util.Map;
import static org.assertj.core.api.Assertions.assertThat;

/** 仅 -Plive 时执行；必须连接实际 MySQL/Redis，不使用 H2，不写库。 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("dev")
class InfrastructureLiveIT {
    @Autowired TestRestTemplate http;
    @Autowired JdbcTemplate jdbc;
    @Autowired StringRedisTemplate redis;
    @Autowired HealthEndpoint health;
    @Autowired FilmMapper mapper;

    @Test
    @SuppressWarnings("unchecked")
    void httpPaginationMatchesPhysicalDatabaseAndMapsEveryColumn() {
        assertThat(jdbc.queryForObject("SELECT DATABASE()", String.class)).isEqualTo("pzh_cinema");
        Long total = jdbc.queryForObject("SELECT COUNT(*) FROM film WHERE publish_status='PUBLISHED'", Long.class);
        var expected = jdbc.queryForList("SELECT id,film_name FROM film WHERE publish_status='PUBLISHED' ORDER BY id DESC LIMIT 1");
        var response = http.getForEntity("/api/v1/films?page=1&pageSize=1", Map.class);
        assertThat(response.getStatusCode().value()).isEqualTo(200);
        assertThat(response.getBody().get("code")).isEqualTo(0);
        var data = (Map<String,Object>) response.getBody().get("data");
        assertThat(((Number)data.get("total")).longValue()).isEqualTo(total);
        var records = (java.util.List<Map<String,Object>>) data.get("records");
        if (expected.isEmpty()) {
            assertThat(records).isEmpty();
        } else {
            assertThat(records).hasSize(1);
            assertThat(records.getFirst().get("id")).isEqualTo(expected.getFirst().get("id").toString());
            assertThat(records.getFirst().get("filmName")).isEqualTo(expected.getFirst().get("film_name"));
            // selectById 读取全部 17 列，包含 JSON 与 DATETIME 的真实映射。
            var entity = mapper.selectById(expected.getFirst().get("id").toString());
            assertThat(entity.getCreatedAt()).isNotNull();
            assertThat(entity.getUpdatedAt()).isNotNull();
        }
    }

    @Test
    @SuppressWarnings("unchecked")
    void highPageIsEmptyInsteadOfWrappingToFirstPage() {
        var response = http.getForEntity("/api/v1/films?page=1000000&pageSize=100", Map.class);
        assertThat(response.getStatusCode().value()).isEqualTo(200);
        assertThat((java.util.List<?>) ((Map<String,Object>) response.getBody().get("data")).get("records")).isEmpty();
    }

    @Test
    void mysqlRedisAndHealthAreAvailable() {
        assertThat(jdbc.queryForObject("SELECT 1", Integer.class)).isEqualTo(1);
        try (var connection = redis.getConnectionFactory().getConnection()) {
            assertThat(connection.ping()).isEqualTo("PONG");
        }
        assertThat(health.health().getStatus()).isEqualTo(Status.UP);
        var result = http.getForEntity("/actuator/health", Map.class);
        assertThat(result.getStatusCode().value()).isEqualTo(200);
        assertThat(result.getBody()).containsEntry("status", "UP").doesNotContainKey("components");
    }

    @Test
    @SuppressWarnings("unchecked")
    void swaggerDocumentAndBundledUiAssetsAreAccessible() {
        var docs = http.getForEntity("/v3/api-docs", Map.class);
        assertThat(docs.getStatusCode().value()).isEqualTo(200);
        assertThat(docs.getBody()).containsKeys("openapi", "paths");
        assertThat((Map<String,Object>)docs.getBody().get("paths")).containsKey("/api/v1/films");
        assertThat(http.getForEntity("/swagger-ui/index.html", String.class).getStatusCode().value()).isEqualTo(200);
        assertThat(http.getForEntity("/swagger-ui/swagger-ui-bundle.js", String.class).getStatusCode().value()).isEqualTo(200);
    }

    @Test
    void actualServerRejectsBadPaginationAndProtectedRoutes() {
        var invalid = http.getForEntity("/api/v1/films?pageSize=101", Map.class);
        assertThat(invalid.getStatusCode().value()).isEqualTo(400);
        assertThat(invalid.getBody()).containsEntry("code",40000).containsKey("requestId");
        var protectedRoute = http.getForEntity("/api/v1/admin/users", Map.class);
        assertThat(protectedRoute.getStatusCode().value()).isEqualTo(401);
        assertThat(protectedRoute.getBody()).containsEntry("code",40100);
    }
}
