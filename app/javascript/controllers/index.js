import { application } from "controllers/application"
import HelloController from "controllers/hello_controller"
import SidebarController from "controllers/sidebar_controller"

application.register("hello", HelloController)
application.register("sidebar", SidebarController)
