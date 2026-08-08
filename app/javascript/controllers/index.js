import { application } from "controllers/application"
import HelloController from "controllers/hello_controller"
import ImagePreviewController from "controllers/image_preview_controller"
import SidebarController from "controllers/sidebar_controller"
import SelectController from "controllers/select_controller"
import VideoPreviewController from "controllers/video_preview_controller"
import LessonTypeController from "controllers/lesson_type_controller"
import FileUploadController from "controllers/file_upload_controller"
import LessonProgressController from "controllers/lesson_progress_controller"

application.register("hello", HelloController)
application.register("image-preview", ImagePreviewController)
application.register("sidebar", SidebarController)
application.register("select", SelectController)
application.register("video-preview", VideoPreviewController)
application.register("lesson-type", LessonTypeController)
application.register("file-upload", FileUploadController)
application.register("lesson-progress", LessonProgressController)
