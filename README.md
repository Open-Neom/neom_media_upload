# neom_media_upload
neom_media_upload is a crucial module within the Open Neom ecosystem, exclusively
dedicated to handling all aspects of media file selection, processing, and uploading.
It provides a robust and streamlined pipeline for users to select images, videos, audio,
and documents from their device's gallery or file system, perform necessary optimizations
(like compression), and securely upload them to the cloud.

This module is designed to abstract the complexities of media handling, ensuring a consistent
and efficient experience across the application wherever media uploads are required 
(e.g., for posts, profile images, event covers).
It strictly adheres to Open Neom's Clean Architecture principles, promoting clear separation of concerns,
high testability, and seamless integration with neom_core for core services and neom_commons for shared UI components.
Its focus on efficient media processing aligns with the Tecnozenism philosophy of optimizing digital interactions.

🌟 Features & Responsibilities
neom_media_upload provides a comprehensive set of functionalities for media handling:
•	Media Selection: Supports picking single or multiple media files (images, videos, audio, documents)
    from the device's gallery or file picker.
•	Media Type Detection: Automatically identifies the type of media (image, video, audio, document) based on file extension.
•	File Size Validation & Compression:
    o	Validates media file sizes against predefined limits (maxImageFileSize, maxVideoFileSize, etc.).
    o	Automatically compresses images (JPEG/PNG) and videos to meet size requirements and optimize upload performance.
•	Video Thumbnail Generation: Extracts high-quality thumbnail images from selected video files.
•	Cloud Upload Integration: Handles the secure upload of processed media files (and their thumbnails)
    to cloud storage (e.g., Firebase Storage), utilizing AppUploadFirestore for the actual upload mechanism.
•	Media File Management: Provides methods to get, set, and clear the currently selected media file,
    ensuring state consistency across the upload process.
•	Platform-Specific Utilities: Includes utilities for handling PlatformFile objects and
    converting them to standard File objects.
•	User Interface for Selection: Offers a dedicated MediaUploadPage with a MediaUploadGrid
    to browse and select media from the device's gallery.

📦 Technical Highlights / Why it Matters (for developers)
For developers, neom_media_upload serves as an excellent case study for:
•	Complex File Handling: Demonstrates robust handling of various file types, including picking, validation, and processing.
•	External Package Integration: Shows effective integration of popular Flutter packages like file_picker, image_picker,
    photo_manager, flutter_image_compress, and video_compress for media functionalities.
•	Service-Oriented Architecture: Implements the MediaUploadService interface, showcasing how media upload logic
    is decoupled and consumed by other modules (e.g., neom_onboarding, neom_posts).
•	Asynchronous Operations: Manages complex asynchronous tasks (file compression, thumbnail generation, cloud uploads)
    with clear state management (isLoading, isUploading).
•	Performance Optimization: Includes logic for media compression to ensure efficient uploads and a smoother user experience,
    particularly important for mobile applications.
•	Utility Class Design: Features MediaUploadUtilities for encapsulating common media processing functions,
    promoting code reusability and clarity.
•	UI for Media Browsing: Provides an example of building a custom gallery grid using photo_manager
    for efficient display of device media.

How it Supports the Open Neom Initiative
neom_media_upload is vital to the Open Neom ecosystem and the broader Tecnozenism vision by:
•	Enabling Rich Content Creation: It provides the foundational capability for users to share diverse media 
    (photos, videos, audio, documents), enriching the content within the platform and fostering creative expression.
•	Facilitating Biofeedback & Research Data: Its ability to handle various media types opens avenues for integrating
    and uploading data from cognitive and biofeedback technologies (e.g., video recordings for behavioral analysis, audio for vocal patterns).
•	Optimizing Digital Interaction: By handling file compression and efficient uploads, it contributes to a smoother
    and less frustrating digital experience, aligning with the Tecnozenism principle of conscious technology use.
•	Showcasing Modularity: As a self-contained module, it exemplifies Open Neom's "Plug-and-Play" architecture,
    demonstrating how complex functionalities can be built independently and integrated seamlessly.
•	Supporting Decentralized Content: Provides the mechanism for users to contribute their own media, supporting 
    the vision of a decentralized and community-driven content ecosystem.

🚀 Usage
This module provides the MediaUploadService interface and its implementation (MediaUploadController), 
along with a MediaUploadPage for UI-driven media selection. Other modules (e.g., neom_onboarding for profile images,
neom_posts for content creation) inject and utilize MediaUploadService to handle their media upload requirements.

🛠️ Dependencies
neom_media_upload relies on neom_core for core services, models, and routing constants, and on neom_commons
for reusable UI components, themes, and utility functions. It also directly depends on various media-related 
Flutter packages (file_picker, image_picker, photo_manager, flutter_image_compress, video_compress).

🤝 Contributing
We welcome contributions to the neom_media_upload module! If you're passionate about media processing,
file handling, or optimizing upload experiences, your contributions can significantly enhance Open Neom's capabilities.

To understand the broader architectural context of Open Neom and how neom_media_upload fits into the overall
vision of Tecnozenism, please refer to the main project's MANIFEST.md.

For guidance on how to contribute to Open Neom and to understand the various levels of learning and engagement
possible within the project, consult our comprehensive guide: Learning Flutter Through Open Neom: A Comprehensive Path.

📄 License
This project is licensed under the Apache License, Version 2.0, January 2004. See the LICENSE file for details.
