package com.springboot.manhaji.service.storage;

import com.springboot.manhaji.config.StorageConfigProperties;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class FileStorageService {

    private final StorageConfigProperties storageConfig;

    private Path uploadDir;
    private Path audioDir;
    private Path imageDir;

    @PostConstruct
    public void init() {
        try {
            uploadDir = Paths.get(storageConfig.getUploadDir()).toAbsolutePath().normalize();
            audioDir = Paths.get(storageConfig.getAudioDir()).toAbsolutePath().normalize();
            imageDir = Paths.get(storageConfig.getImageDir()).toAbsolutePath().normalize();

            Files.createDirectories(uploadDir);
            Files.createDirectories(audioDir);
            Files.createDirectories(imageDir);

            log.info("Storage directories initialized: {}", uploadDir);
        } catch (IOException e) {
            throw new RuntimeException("Could not create upload directories", e);
        }
    }

    /**
     * Save an image file and return its URL path (relative to server root).
     */
    public String saveImage(byte[] data, String filename) throws IOException {
        String safeFilename = generateSafeFilename(filename);
        Path target = imageDir.resolve(safeFilename);
        Files.write(target, data, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
        log.info("Saved image: {}", target);
        return "uploads/images/" + safeFilename;
    }

    /**
     * Save an audio file and return its URL path.
     */
    public String saveAudio(byte[] data, String filename) throws IOException {
        String safeFilename = generateSafeFilename(filename);
        Path target = audioDir.resolve(safeFilename);
        Files.write(target, data, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
        log.info("Saved audio: {}", target);
        return "uploads/audio/" + safeFilename;
    }

    /**
     * Save an image to a subject-specific subdirectory.
     */
    public String saveSubjectImage(byte[] data, String subjectCode, String filename) throws IOException {
        Path subjectDir = imageDir.resolve(subjectCode);
        Files.createDirectories(subjectDir);

        String safeFilename = generateSafeFilename(filename);
        Path target = subjectDir.resolve(safeFilename);
        Files.write(target, data, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
        log.info("Saved subject image: {}", target);
        return "uploads/images/" + subjectCode + "/" + safeFilename;
    }

    /**
     * Check if a file already exists (for caching).
     */
    public boolean audioExists(String filename) {
        return Files.exists(audioDir.resolve(filename));
    }

    public boolean imageExists(String filename) {
        return Files.exists(imageDir.resolve(filename));
    }

    /**
     * Get the absolute path of an audio file.
     */
    public Path getAudioPath(String filename) {
        return audioDir.resolve(filename);
    }

    public Path getImagePath(String filename) {
        return imageDir.resolve(filename);
    }

    private String generateSafeFilename(String originalFilename) {
        String extension = "";
        int dotIndex = originalFilename.lastIndexOf('.');
        if (dotIndex > 0) {
            extension = originalFilename.substring(dotIndex);
        }
        return UUID.randomUUID().toString().substring(0, 8) + "_" + sanitizeFilename(originalFilename);
    }

    private String sanitizeFilename(String filename) {
        return filename.replaceAll("[^a-zA-Z0-9._-]", "_");
    }
}
