resource "oci_streaming_stream" "this" {
  # compartment_id and stream_pool_id are mutually exclusive in the OCI API:
  # CreateStreamDetails rejects a request that carries both. When a pool is
  # supplied the stream inherits that pool's compartment, so compartment_id is
  # deliberately not sent.
  compartment_id     = var.stream_pool_id == null ? var.compartment_id : null
  name               = var.name
  partitions         = var.partitions
  stream_pool_id     = var.stream_pool_id
  retention_in_hours = var.retention_in_hours

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition     = var.compartment_id != null || var.stream_pool_id != null
      error_message = "One of compartment_id or stream_pool_id must be set: compartment_id creates the stream in that compartment's DefaultPool, stream_pool_id places it in an existing pool."
    }
  }
}
