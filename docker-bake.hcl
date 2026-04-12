variable "BUN_VERSION" {
  default = "1.3.12"
}

variable "ALPINE_VERSION" {
  default = "3.21"
}

variable "REGISTRIES" {
  # Comma-separated list: "docker.io/username,ghcr.io/username"
  default = ""
}

function "tags" {
  params = [variant]
  result = flatten([
    for registry in split(",", REGISTRIES) : registry == "" ? [] : concat(
      # Full version: 1.3.12 / 1.3.12-upx
      [variant == "default"
        ? "${registry}/bun-nano:${BUN_VERSION}"
        : "${registry}/bun-nano:${BUN_VERSION}-${variant}"],
      # Minor version: 1.3 / 1.3-upx
      [variant == "default"
        ? "${registry}/bun-nano:${join(".", slice(split(".", BUN_VERSION), 0, 2))}"
        : "${registry}/bun-nano:${join(".", slice(split(".", BUN_VERSION), 0, 2))}-${variant}"],
      # Major version: 1 / 1-upx
      [variant == "default"
        ? "${registry}/bun-nano:${split(".", BUN_VERSION)[0]}"
        : "${registry}/bun-nano:${split(".", BUN_VERSION)[0]}-${variant}"],
      # latest / upx
      [variant == "default"
        ? "${registry}/bun-nano:latest"
        : "${registry}/bun-nano:${variant}"],
    )
  ])
}

group "default" {
  targets = ["default", "upx"]
}

target "default" {
  dockerfile = "Dockerfile"
  target     = "default"
  platforms  = ["linux/amd64", "linux/arm64"]
  args = {
    BUN_VERSION    = BUN_VERSION
    ALPINE_VERSION = ALPINE_VERSION
  }
  tags = tags("default")
}

target "upx" {
  dockerfile = "Dockerfile"
  target     = "upx"
  platforms  = ["linux/amd64", "linux/arm64"]
  args = {
    BUN_VERSION    = BUN_VERSION
    ALPINE_VERSION = ALPINE_VERSION
  }
  tags = tags("upx")
}

# Local testing target — single platform, no registry push
target "local" {
  dockerfile = "Dockerfile"
  target     = "default"
  platforms  = ["linux/amd64"]
  args = {
    BUN_VERSION    = BUN_VERSION
    ALPINE_VERSION = ALPINE_VERSION
  }
  tags = ["bun-nano:local"]
}
