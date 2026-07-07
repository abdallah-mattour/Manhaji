package com.springboot.manhaji.config;

import io.jsonwebtoken.io.Decoders;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.validation.annotation.Validated;

@Configuration
@ConfigurationProperties(prefix = "app.jwt")
@Validated
@Getter
@Setter
public class JwtProperties {

    private static final int MIN_SECRET_BYTES = 32;

    @NotBlank(message = "app.jwt.secret is required. Set APP_JWT_SECRET, or activate the local profile with an untracked application-local.properties file.")
    private String secret;

    @Positive(message = "app.jwt.access-token-expiration must be a positive duration in milliseconds.")
    private long accessTokenExpiration = 86_400_000L;

    @Positive(message = "app.jwt.refresh-token-expiration must be a positive duration in milliseconds.")
    private long refreshTokenExpiration = 604_800_000L;

    @AssertTrue(message = "app.jwt.secret must be Base64-encoded and decode to at least 32 bytes. Generate one with: openssl rand -base64 64")
    public boolean isSecretStrongEnough() {
        if (secret == null || secret.isBlank()) {
            return true;
        }

        try {
            return decodedSecret().length >= MIN_SECRET_BYTES;
        } catch (RuntimeException ex) {
            return false;
        }
    }

    public byte[] decodedSecret() {
        return Decoders.BASE64.decode(compactSecret());
    }

    private String compactSecret() {
        return secret == null ? "" : secret.replaceAll("\\s+", "");
    }
}
