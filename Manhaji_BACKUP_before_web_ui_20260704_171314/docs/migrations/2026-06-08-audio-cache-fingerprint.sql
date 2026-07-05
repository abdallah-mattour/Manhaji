-- ============================================================================
-- Migration: Content-fingerprinted TTS audio cache
-- Date     : 2026-06-08
-- Risk     : very low (two additive nullable columns)
-- ============================================================================
--
-- What this does
-- --------------
-- Adds `audio_text_hash` to `questions` and `lessons`. It stores a SHA-256 of
-- the spoken text that the cached TTS clip at `audio_url` was generated from
-- (see TtsService.speechFingerprint). AudioController serves the cached clip
-- only while this hash still matches the current text's fingerprint; when the
-- text is edited (the FILL_BLANK "___" sanitizer, a TRUE_FALSE/RTL rewrite, or
-- any future curriculum fix) the hashes diverge and the clip regenerates on the
-- next play instead of serving stale audio.
--
-- Why a script (vs relying on ddl-auto: update)
-- ---------------------------------------------
-- You don't strictly need it: Hibernate's `ddl-auto: update` ADDS new nullable
-- columns on the first boot with the updated entities, so on this project the
-- columns appear automatically. This script is here for completeness / for any
-- environment that doesn't run ddl-auto.
--
-- Self-healing note
-- -----------------
-- No data backfill is needed. Existing TTS clips have `audio_text_hash = NULL`,
-- which never matches a computed fingerprint, so each one regenerates exactly
-- once the next time its speaker button is tapped — automatically clearing any
-- audio that was generated before the "___" / TF / RTL text fixes. Authored
-- asset audio (URLs NOT under `uploads/audio/`) is left untouched by the
-- controller regardless of hash, so bundled reciter/native-speaker clips are
-- never overwritten by synthesis.
--
-- How to run
-- ----------
--     mysql -u root -p manhaji_db < docs/migrations/2026-06-08-audio-cache-fingerprint.sql
-- ============================================================================

-- NOTE (MySQL 8 compatibility): MySQL 8.0 does NOT support
-- `ADD COLUMN IF NOT EXISTS` (that's MariaDB syntax). On an already-booted DB
-- Hibernate's ddl-auto will have added these columns already, so each ALTER
-- below errors "Duplicate column name" — that's expected; skip it and continue.

ALTER TABLE questions ADD COLUMN audio_text_hash VARCHAR(64) NULL;
ALTER TABLE lessons   ADD COLUMN audio_text_hash VARCHAR(64) NULL;

-- Sanity check
SELECT 'questions.audio_text_hash present?' AS check_name,
       IF(COUNT(*) = 1, 'OK', 'MISSING') AS result
FROM information_schema.columns
WHERE table_schema = DATABASE() AND table_name = 'questions' AND column_name = 'audio_text_hash'
UNION ALL
SELECT 'lessons.audio_text_hash present?',
       IF(COUNT(*) = 1, 'OK', 'MISSING')
FROM information_schema.columns
WHERE table_schema = DATABASE() AND table_name = 'lessons' AND column_name = 'audio_text_hash';
