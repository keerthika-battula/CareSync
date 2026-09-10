package com.caresync.backend.config;

import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class QuartzConfig {

    private final ApplicationContext applicationContext;

    public QuartzConfig(ApplicationContext applicationContext) {
        this.applicationContext = applicationContext;
    }

    @Bean
    public AutowiringSpringBeanJobFactory springBeanJobFactory() {
        AutowiringSpringBeanJobFactory factory = new AutowiringSpringBeanJobFactory();
        factory.setApplicationContext(applicationContext);
        return factory;
    }
}
