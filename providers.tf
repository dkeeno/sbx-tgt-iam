# =============================================================================
# providers.tf — AWS provider config
# =============================================================================

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project    = "wc003-simulation"
      ManagedBy  = "terraform"
      Repository = "sbx-tgt-iam"
      Simulation = "wc003-phase2"
    }
  }
}
