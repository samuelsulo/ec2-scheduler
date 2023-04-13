variable "schedule_start_instances_name" {
  description = "EventBridge schedule that will start instances."
  type        = string
  default     = "start-instances"
}

variable "schedule_stop_instances_name" {
  description = "EventBridge schedule that will stop instances."
  type        = string
  default     = "stop-instances"
}
