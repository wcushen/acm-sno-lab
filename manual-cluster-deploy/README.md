# OCP Config

```bash
# download the installer
OPENSHIFT_VERSION=4.17.7
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OPENSHIFT_VERSION}/openshift-install-linux.tar.gz
tar xzvf openshift-install-linux.tar.gz
chmod 755 openshift-install
#
mkdir cluster
# needed deps
sudo dnf install /usr/bin/nmstatectl -y
#
cp install-config.yaml agent-config.yaml cluster/
#
./openshift-install --dir cluster agent create image
```

Creates `cluster/agent.x86_64.iso` and `cluster/auth` - use to install on bare metal and wait-for install to complete.

```bash
sudo cp cluster/agent.x86_64.iso /var/www/html/agent.x86_64.iso
```

Bootstrap.

```bash
./openshift-install --dir cluster agent wait-for bootstrap-complete --log-level=debug
```

Install.

```bash
./openshift-install --dir cluster agent wait-for install-complete --log-level=debug
```