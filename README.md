# acm-sno-lab

Bare Metal - ACM > MCE > HCP Spokes

    ACM - SNO Hub cluster
    MCE - Managed 3-Node Compact Hosting cluster
    hcp-{1..4} - Managed Spoke HCP clusters

Component View

![acm-mce.png](images/acm-mce.png)

Cluster Topology View

![acm-mce-topology2.png](images/acm-mce-topology2.png)

ACM > MCE > HCP auto-import

- Policy to auto-import HCP Spokes

![acm-mce-discovery1.png](images/acm-mce-discovery1.png)

ACM HUB Clusters

- Global Policy-as-code management via GitOps

![acm-hub-clusters.png](images/acm-hub-clusters.png)

MCE Clusters

- Lifecycle HCP Spokes via GitOps from ACM

![mce-clusters.png](images/mce-clusters.png)

InfraEnvs - MCE & BareMetal

![mce-infra-env.png](images/mce-infra-env.png)
![bm-infra-env.png](images/bm-infra-env.png)

GitOps Clusters

![gitops-clusters.png](images/gitops-clusters.png)

Policy-as-Code

![policy-as-code.png](images/policy-as-code.png)

## Useful Links

- https://github.com/stolostron/hypershift-addon-operator/blob/main/docs/discovering_hostedclusters.md
- https://github.com/stolostron/hypershift-addon-operator/blob/main/docs/hosting_cluster_topologies.md
- https://labs.sysdeseng.com/hypershift-baremetal-lab/4.15/hcp-deployment.html
