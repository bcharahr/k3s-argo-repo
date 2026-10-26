#!/usr/bin/env bash
# Log in to the k3s Vault with a token. Source it so VAULT_ADDR stays set:
#   source scripts/vault.sh
export VAULT_ADDR=http://vault-k3s.3aevolution.com

if [ -n "${TOKEN:-}" ]; then
  vault login -method=token -no-print token="$TOKEN"
else
  vault login -method=token -no-print
fi
vault token lookup -format=json | grep -E '"(display_name|policies|ttl)"' -A0
