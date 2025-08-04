### 1.0.0 - Initial Release & Decoupling from neom_posts

This marks the **initial official release (v1.0.0)** of `neom_media_upload` as a standalone, independent module within the Open Neom ecosystem. Previously, media upload functionalities were often embedded directly within content creation modules like `neom_posts`. This decoupling is a crucial step in formalizing the media handling layer, enhancing modularity, and strengthening Open Neom's adherence to Clean Architecture principles.

**Key Highlights of this Release:**

* **Module Decoupling & Self-Containment:**
    * `neom_media_upload` now encapsulates all media file selection, processing (compression, thumbnail generation), and upload logic, completely separated from content-specific modules.
    * This ensures that `neom_media_upload` is a highly focused and reusable component for any media-related operation across the application.

* **Centralized Media Handling Pipeline:**
    * Provides a comprehensive set of functionalities for media management, including:
        * Picking single or multiple media files (images, videos, audio, documents).
        * Automatic media type detection.
        * File size validation and intelligent compression for images and videos.
        * Generation of video thumbnails.
        * Secure upload of media to cloud storage.

* **Direct External Dependencies:**
    * Now directly manages its external media-related dependencies (`file_picker`, `image_picker`, `photo_manager`, `flutter_image_compress`, `video_compress`), centralizing their usage within this module.

* **Enhanced Maintainability & Reusability:**
    * As a dedicated and self-contained module, `neom_media_upload` is now significantly easier to maintain, test, and extend. Any module requiring media upload capabilities can simply depend on `neom_media_upload` and its `MediaUploadService`.
    * This aligns perfectly with the overall architectural vision of Open Neom, fostering a more collaborative and efficient development environment for media-rich functionalities.

* **Leverages Core Open Neom Modules:**
    * Built upon `neom_core` for foundational services (like `AppUploadFirestore` for the actual upload mechanism) and routing constants, and `neom_commons` for reusable UI components and utilities, ensuring consistency and seamless integration within the ecosystem.