package com.springboot.manhaji.config;

import com.springboot.manhaji.entity.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

@Service
public class JwtService {

    /**
     * Token-type discriminator. Audit-4 fix C5 (2026-05-15): without a
     * tokenType claim, refresh tokens were silently accepted by the bearer
     * filter and could be used as access tokens (defeats refresh rotation,
     * confuses the trust boundary). Now {@link #isAccessToken} and
     * {@link #isRefreshToken} let the filter and refresh endpoint reject
     * mis-typed tokens.
     */
    public static final String TOKEN_TYPE_ACCESS = "ACCESS";
    public static final String TOKEN_TYPE_REFRESH = "REFRESH";
    private static final String CLAIM_TOKEN_TYPE = "tokenType";

    @Value("${app.jwt.secret}")
    private String secretKey;

    @Value("${app.jwt.access-token-expiration}")
    private long accessTokenExpiration;

    @Value("${app.jwt.refresh-token-expiration}")
    private long refreshTokenExpiration;

    public String generateAccessToken(User user) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("role", user.getRole().name());
        claims.put("userId", user.getId());
        claims.put(CLAIM_TOKEN_TYPE, TOKEN_TYPE_ACCESS);
        return buildToken(claims, user.getEmail() != null ? user.getEmail() : user.getPhone(), accessTokenExpiration);
    }

    public String generateRefreshToken(User user) {
        Map<String, Object> claims = new HashMap<>();
        claims.put(CLAIM_TOKEN_TYPE, TOKEN_TYPE_REFRESH);
        return buildToken(claims, user.getEmail() != null ? user.getEmail() : user.getPhone(), refreshTokenExpiration);
    }

    private String buildToken(Map<String, Object> extraClaims, String subject, long expiration) {
        return Jwts.builder()
                .claims(extraClaims)
                .subject(subject)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expiration))
                .signWith(getSigningKey())
                .compact();
    }

    public String extractSubject(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public Long extractUserId(String token) {
        return extractClaim(token, claims -> claims.get("userId", Long.class));
    }

    public String extractRole(String token) {
        return extractClaim(token, claims -> claims.get("role", String.class));
    }

    public boolean isTokenValid(String token) {
        try {
            return !isTokenExpired(token);
        } catch (Exception e) {
            return false;
        }
    }

    /** Audit-4 fix C5: only ACCESS tokens may pass the bearer auth filter. */
    public boolean isAccessToken(String token) {
        try {
            String type = extractClaim(token, c -> c.get(CLAIM_TOKEN_TYPE, String.class));
            return TOKEN_TYPE_ACCESS.equals(type) && !isTokenExpired(token);
        } catch (Exception e) {
            return false;
        }
    }

    /** Audit-4 fix C5: only REFRESH tokens may be used at the refresh endpoint. */
    public boolean isRefreshToken(String token) {
        try {
            String type = extractClaim(token, c -> c.get(CLAIM_TOKEN_TYPE, String.class));
            return TOKEN_TYPE_REFRESH.equals(type) && !isTokenExpired(token);
        } catch (Exception e) {
            return false;
        }
    }

    private boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    private Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    private <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private SecretKey getSigningKey() {
        // Audit fix S2 (2026-04-29): the previous implementation Base64-encoded
        // the plaintext secret bytes and immediately Base64-decoded them — a
        // round-trip no-op that yielded the raw UTF-8 bytes of the plaintext.
        // The signing key must come from a single, well-defined Base64 decode
        // of a properly-generated random key (see application.yaml note + README).
        return Keys.hmacShaKeyFor(Decoders.BASE64.decode(secretKey));
    }
}
