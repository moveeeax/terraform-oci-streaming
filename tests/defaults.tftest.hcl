# Requires Terraform >= 1.7 for mock_provider. This is a test-only requirement:
# do not raise required_version in versions.tf, which would break consumers.

mock_provider "oci" {}

variables {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartmentocid"
  name           = "unit-test-stream"
}

run "defaults_are_safe" {
  command = plan

  assert {
    condition     = oci_streaming_stream.this.retention_in_hours == 24
    error_message = "Default retention must be 24 hours, the OCI minimum and default."
  }

  assert {
    condition     = oci_streaming_stream.this.partitions == 1
    error_message = "Default partition count must be 1."
  }

  assert {
    condition     = oci_streaming_stream.this.name == "unit-test-stream"
    error_message = "name must be passed through to the stream unchanged."
  }
}

run "compartment_is_sent_when_no_pool_given" {
  command = plan

  assert {
    condition     = oci_streaming_stream.this.compartment_id == "ocid1.compartment.oc1..aaaaaaaaexamplecompartmentocid"
    error_message = "With no stream_pool_id the stream must be created in var.compartment_id."
  }
}

run "explicit_values_are_passed_through" {
  command = plan

  variables {
    partitions         = 6
    retention_in_hours = 168
    freeform_tags      = { Environment = "production" }
  }

  assert {
    condition     = oci_streaming_stream.this.partitions == 6
    error_message = "partitions must be passed through unchanged."
  }

  assert {
    condition     = oci_streaming_stream.this.retention_in_hours == 168
    error_message = "retention_in_hours must be passed through unchanged; 168 is the OCI maximum."
  }

  assert {
    condition     = oci_streaming_stream.this.freeform_tags["Environment"] == "production"
    error_message = "freeform_tags must be passed through unchanged."
  }
}

run "pool_placement_is_passed_through" {
  command = plan

  variables {
    stream_pool_id = "ocid1.streampool.oc1..aaaaaaaaexamplestreampoolocid"
  }

  assert {
    condition     = oci_streaming_stream.this.stream_pool_id == "ocid1.streampool.oc1..aaaaaaaaexamplestreampoolocid"
    error_message = "stream_pool_id must be passed through so the stream lands in the given pool."
  }
}
