import { application } from "controllers/application"
import HelloController from "controllers/hello_controller"
import ImagePreviewController from "controllers/image_preview_controller"
import SidebarController from "controllers/sidebar_controller"
import SelectController from "controllers/select_controller"
import VideoPreviewController from "controllers/video_preview_controller"

application.register("hello", HelloController)
application.register("image-preview", ImagePreviewController)
application.register("sidebar", SidebarController)
application.register("select", SelectController)
application.register("video-preview", VideoPreviewController)
