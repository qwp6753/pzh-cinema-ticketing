package com.pzh.cinema.film.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;
import java.time.LocalDateTime;

/** 严格对应既有 film 表的 17 个字段，没有虚构逻辑删除、租户或版本列。 */
@Getter
@Setter
@TableName("film")
public class FilmEntity {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String filmName;
    private String originalName;
    private String posterUrl;
    private String trailerUrl;
    private String director;
    // 当前只读取原始 JSON 文本，不增加演员表或改变既有 JSON 类型。
    private String castList;
    private String country;
    private String language;
    private Integer durationMinutes;
    private LocalDate releaseDate;
    private String synopsis;
    private String releaseStatus;
    private String publishStatus;
    private Long heatScore;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
