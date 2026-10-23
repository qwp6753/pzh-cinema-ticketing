package com.pzh.cinema.common.api;

import jakarta.validation.Validation;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;

class PageQueryTest {
    @Test
    void rejectsUnboundedPageSizesBeforeTheyReachDatabase() {
        try (ValidatorFactory factory = Validation.buildDefaultValidatorFactory()) {
            var query = new PageQuery();
            query.setPageSize(101L);
            assertThat(factory.getValidator().validate(query)).hasSize(1);
        }
    }
}
