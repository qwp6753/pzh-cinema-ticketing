package com.pzh.cinema.film.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.pzh.cinema.film.entity.FilmEntity;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface FilmMapper extends BaseMapper<FilmEntity> {
}
