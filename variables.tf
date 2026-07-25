variable "compartment_id" {
  description = <<-EOT
    OCID of the compartment in which to create the stream. The stream is placed in
    that compartment's DefaultPool. Ignored when stream_pool_id is set, because the
    OCI API rejects a create request carrying both; the stream then inherits the
    pool's compartment. One of compartment_id or stream_pool_id must be set.
  EOT
  type        = string
  default     = null
}

variable "name" {
  description = <<-EOT
    Name of the stream. Immutable: OCI cannot rename a stream, so changing this
    destroys and recreates it, permanently discarding every message still inside
    the retention window along with all consumer group offsets.
  EOT
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "partitions" {
  description = <<-EOT
    Number of partitions in the stream. Immutable: OCI has no repartition operation,
    so changing this destroys and recreates the stream, permanently discarding every
    message still inside the retention window along with all consumer group offsets.
    Size it for peak throughput up front rather than scaling it later.
  EOT
  type        = number
  default     = 1

  validation {
    condition     = var.partitions >= 1 && floor(var.partitions) == var.partitions
    error_message = "partitions must be a whole number of at least 1."
  }
}

variable "stream_pool_id" {
  description = <<-EOT
    OCID of an existing stream pool to place the stream in. Null uses the
    compartment's DefaultPool, which Oracle creates with a public endpoint and
    Oracle-managed encryption keys. Supply a pool to get a private endpoint or a
    customer-managed encryption key; this module does not manage stream pools.
  EOT
  type        = string
  default     = null
}

variable "retention_in_hours" {
  description = <<-EOT
    Retention period of the stream in hours (24 to 168). Immutable: OCI cannot change
    the retention of an existing stream, so changing this destroys and recreates it,
    permanently discarding every message still inside the retention window along with
    all consumer group offsets.
  EOT
  type        = number
  default     = 24

  validation {
    condition = (
      var.retention_in_hours >= 24 &&
      var.retention_in_hours <= 168 &&
      floor(var.retention_in_hours) == var.retention_in_hours
    )
    error_message = "retention_in_hours must be a whole number between 24 and 168."
  }
}

variable "freeform_tags" {
  description = "Free-form tags applied to the stream."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to the stream, keyed as \"namespace.key\"."
  type        = map(string)
  default     = {}
}
