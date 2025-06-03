## Generating the SOPs secret

```bash
export SOPS_AGE_KEY_FILE=$(pwd)/secrets/age-key-admin.txt
export AGE_RECIPIENTS=$(grep public secrets/age-key-admin.txt | awk '{print $4}')

cat <<EOF | sops --encrypt --age "$AGE_RECIPIENTS" > gitops/applications/welcome/overlay/a-team/secret.enc
message: Hello there from Will!
EOF
```