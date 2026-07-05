package com.springboot.manhaji;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.EnableAspectJAutoProxy;

@SpringBootApplication
// Tier B / B3 (2026-05-15): admin audit logs require @Aspect support.
// Spring Boot's starter-aop usually adds this; we add it explicitly because
// we depend on aspectjweaver directly (see build.gradle.kts comment).
@EnableAspectJAutoProxy(proxyTargetClass = true)
public class ManhajiApplication {

    public static void main(String[] args) {
        SpringApplication.run(ManhajiApplication.class, args);
    }

}
