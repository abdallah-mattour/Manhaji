package com.springboot.manhaji.support;

import com.springboot.manhaji.entity.AuditLog;
import com.springboot.manhaji.repository.AuditLogRepository;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.Arrays;
import java.util.stream.Collectors;

/**
 * Tier B / B3 (2026-05-15): writes an {@link AuditLog} row around every
 * public method on {@code AdminController}. Closes FR-11.2 from the proposal.
 *
 * <p>Pointcut deliberately narrow — we don't want to audit reads to
 * unrelated controllers (TeacherController dashboards, ParentController, etc.)
 * because the resulting volume would overwhelm the table and the audit
 * loses its meaning. Admin-only is the right scope.
 *
 * <p>The aspect catches exceptions and records {@code success=false} but
 * does NOT swallow them — the original error still propagates so the client
 * sees the right response code.
 */
@Aspect
@Component
@RequiredArgsConstructor
@Slf4j
public class AdminActionAuditAspect {

    private final AuditLogRepository auditLogRepository;

    @Around("execution(public * com.springboot.manhaji.controller.AdminController.*(..))")
    public Object auditAdminAction(ProceedingJoinPoint pjp) throws Throwable {
        String methodName = pjp.getSignature().getName();
        String argsSummary = summariseArgs(pjp.getArgs());

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        Long actorId = (auth != null && auth.getPrincipal() instanceof Long id) ? id : null;
        String actorRole = auth == null ? null : auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .filter(a -> a.startsWith("ROLE_"))
                .findFirst().orElse(null);

        String httpMethod = null;
        String path = null;
        var attrs = RequestContextHolder.getRequestAttributes();
        if (attrs instanceof ServletRequestAttributes sra) {
            HttpServletRequest req = sra.getRequest();
            httpMethod = req.getMethod();
            path = req.getRequestURI();
        }

        Object result;
        boolean success = true;
        Throwable thrown = null;
        try {
            result = pjp.proceed();
        } catch (Throwable t) {
            success = false;
            thrown = t;
            result = null;
        }

        try {
            String details = success
                    ? "args=" + argsSummary
                    : "args=" + argsSummary + " ex=" + thrown.getClass().getSimpleName();
            AuditLog entry = AuditLog.builder()
                    .actorUserId(actorId)
                    .actorRole(actorRole)
                    .action(methodName)
                    .details(truncate(details, 510))
                    .httpMethod(httpMethod)
                    .path(truncate(path, 510))
                    .success(success)
                    .build();
            auditLogRepository.save(entry);
        } catch (Exception logFailure) {
            // Never let an audit failure mask the original method outcome.
            // Better to lose one log line than to corrupt the response.
            log.warn("Failed to persist audit log for {}: {}", methodName, logFailure.getMessage());
        }

        if (thrown != null) throw thrown;
        return result;
    }

    private static String summariseArgs(Object[] args) {
        if (args == null || args.length == 0) return "[]";
        return Arrays.stream(args)
                .map(a -> a == null ? "null" : a.getClass().getSimpleName())
                .collect(Collectors.joining(",", "[", "]"));
    }

    private static String truncate(String s, int max) {
        if (s == null) return null;
        return s.length() <= max ? s : s.substring(0, max);
    }
}
