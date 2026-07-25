# Requires Terraform >= 1.7 for mock_provider. This is a test-only requirement:
# do not raise required_version in versions.tf, which would break consumers.

mock_provider "oci" {}

variables {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartmentocid"
  name           = "unit-test-stream"
}

run "rejects_retention_below_oci_minimum" {
  command = plan

  variables {
    retention_in_hours = 23
  }

  expect_failures = [var.retention_in_hours]
}

run "rejects_retention_above_oci_maximum" {
  command = plan

  variables {
    retention_in_hours = 169
  }

  expect_failures = [var.retention_in_hours]
}

# A fractional retention passes a bare range check but is rejected by the
# provider, which expects an integer.
run "rejects_fractional_retention" {
  command = plan

  variables {
    retention_in_hours = 24.5
  }

  expect_failures = [var.retention_in_hours]
}

run "rejects_zero_partitions" {
  command = plan

  variables {
    partitions = 0
  }

  expect_failures = [var.partitions]
}

# Likewise a fractional partition count passes a bare >= 1 check but is
# rejected by the provider.
run "rejects_fractional_partitions" {
  command = plan

  variables {
    partitions = 2.5
  }

  expect_failures = [var.partitions]
}

run "rejects_empty_name" {
  command = plan

  variables {
    name = "  "
  }

  expect_failures = [var.name]
}

# Neither a compartment nor a pool means the OCI API has nowhere to put the
# stream. Catch it at plan time rather than as an opaque API error at apply.
run "rejects_neither_compartment_nor_pool" {
  command = plan

  variables {
    compartment_id = null
    stream_pool_id = null
  }

  expect_failures = [oci_streaming_stream.this]
}
