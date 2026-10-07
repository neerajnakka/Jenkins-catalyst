#!/usr/bin/env bash
# Block 17/18 — install Trivy, gitleaks, syft and cosign on a Jenkins agent.
set -euo pipefail
ARCH=$(dpkg --print-architecture)

echo "### Trivy"
sudo apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
  | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install -y trivy

echo "### gitleaks"
GL=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | jq -r .tag_name)
curl -sSfL "https://github.com/gitleaks/gitleaks/releases/download/${GL}/gitleaks_${GL#v}_linux_${ARCH}.tar.gz" \
  | sudo tar -xz -C /usr/local/bin gitleaks

echo "### syft (SBOM)"
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin

echo "### cosign (image signing)"
curl -sSfL https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-${ARCH} \
  -o /tmp/cosign && sudo install -m 0755 /tmp/cosign /usr/local/bin/cosign

trivy --version && gitleaks version && syft version && cosign version
