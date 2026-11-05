# terraform-oci-streaming

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
Streaming stream, a Kafka-compatible, partitioned, append-only log for event ingestion.
The stream can live in the default pool for a compartment or in an explicit stream pool.

## Usage

```hcl
module "stream" {
  source = "github.com/moveeeax/terraform-oci-streaming?ref=v1.0.0"

  compartment_id     = var.compartment_id
  name               = "prod-events"
  partitions         = 3
  retention_in_hours = 48

  freeform_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Immutable inputs — changing these destroys the stream

OCI's `UpdateStream` API accepts only `stream_pool_id`, `freeform_tags` and
`defined_tags`. Everything else is fixed at creation, so `name`, `partitions` and
`retention_in_hours` force Terraform to **destroy and recreate** the stream.

Recreation is not a transparent, in-place change. It permanently discards:

- every message still inside the retention window, and
- every consumer group offset, so surviving consumers restart from the beginning
  of a brand new, empty stream.

`terraform plan` reports this only as `must be replaced`, which is easy to wave
through in review and invisible in an auto-apply pipeline. In particular there is
**no repartition operation** in OCI Streaming: raising `partitions` to scale
throughput on a live stream is a data-destroying operation, not a resize. Size
`partitions` for peak throughput up front.

`lifecycle.prevent_destroy` accepts only a literal, so it cannot be driven by a
module variable, and a caller cannot attach one to a resource inside a module.
For streams carrying data you cannot afford to lose, guard them outside the
module instead: require human approval on any plan that reports `must be
replaced`, for example by failing the pipeline on a non-zero destroy count in
`terraform show -json`.

To change an immutable setting without losing messages, stand up a second stream
alongside the first, move producers over, let consumers drain the old stream,
then remove it.

## Encryption and network placement

Both are properties of the **stream pool**, not the stream, and this module does
not manage stream pools:

- Leaving `stream_pool_id` unset places the stream in the compartment's
  `DefaultPool`, which Oracle creates with a **public endpoint** and
  **Oracle-managed encryption keys**. Data is still encrypted at rest, but with a
  key you do not control.
- To use a **customer-managed key** (Vault) or a **private endpoint** in your VCN,
  create an `oci_streaming_stream_pool` yourself with `custom_encryption_key` and
  `private_endpoint_settings`, then pass its OCID as `stream_pool_id`.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| oci       | >= 5.0   |

## Inputs

| Name                 | Description                                                                     | Type          | Default | Required |
|----------------------|---------------------------------------------------------------------------------|---------------|---------|:--------:|
| `compartment_id`     | Compartment OCID; the stream goes in that compartment's `DefaultPool`. Ignored when `stream_pool_id` is set. | `string`      | `null`  |   no\*   |
| `name`               | Name of the stream. **Immutable** — changing it recreates the stream.           | `string`      | n/a     |   yes    |
| `partitions`         | Number of partitions. **Immutable** — changing it recreates the stream.         | `number`      | `1`     |    no    |
| `stream_pool_id`     | Stream pool OCID to place the stream in. Null uses the compartment's `DefaultPool`. | `string`      | `null`  |   no\*   |
| `retention_in_hours` | Retention period in hours (24-168). **Immutable** — changing it recreates the stream. | `number`      | `24`    |    no    |
| `freeform_tags`      | Free-form tags applied to the stream.                                          | `map(string)` | `{}`    |    no    |
| `defined_tags`       | Defined tags applied to the stream, keyed `namespace.key`.                     | `map(string)` | `{}`    |    no    |

\* Exactly one of `compartment_id` or `stream_pool_id` is needed. The OCI API
rejects a create request carrying both, so when `stream_pool_id` is set the module
does not send `compartment_id` and the stream inherits the pool's compartment.
Setting neither fails at plan time with a clear message rather than as an opaque
API error at apply time.

## Outputs

| Name                | Description                                        |
|---------------------|----------------------------------------------------|
| `id`                | OCID of the stream.                                |
| `name`              | Name of the stream.                                |
| `messages_endpoint` | Endpoint to produce to and consume from the stream.|
| `stream_pool_id`    | OCID of the stream pool the stream belongs to.     |
| `state`             | Lifecycle state of the stream.                     |

## Tests

The suite under [`tests/`](tests) runs against a mocked OCI provider, so it needs
no credentials and no network:

```sh
terraform init -backend=false
terraform test
```

`mock_provider` requires Terraform >= 1.7 (OpenTofu >= 1.7). That is a test-only
requirement — the module itself still supports >= 1.5.

## License

[MIT](LICENSE)
