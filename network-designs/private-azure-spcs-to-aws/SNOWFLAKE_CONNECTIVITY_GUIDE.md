# Snowflake Azure SPCS to AWS EC2 (MySQL) Connectivity Guide
## Via Azure Private Link and Site-to-Site VPN

**Version:** 1.0  
**Last Updated:** November 2025  
**Audience:** Snowflake Customers, Cloud Architects, Network Engineers

---

## Executive Summary

This guide outlines the architecture and deployment steps required to enable **Snowflake SPCS containers** (running in Azure) to securely connect to an **AWS MySQL EC2 instance** through Azure Private Link and a Site-to-Site VPN tunnel.

### Architecture Overview

```
Snowflake SPCS Container (Azure)
    ↓ Private Endpoint Connection
Azure Private Link Service
    ↓ Internal Load Balancer
Azure Forwarding VMs (HAProxy)
    ↓ VNet Peering
Azure VPN Gateway
    ↓ IPsec Site-to-Site VPN
AWS VPN Gateway
    ↓ AWS VPC Routing
MySQL EC2 Instance (AWS)
```

### Key Benefits
- ✅ **Fully Private Connectivity** - No public internet exposure
- ✅ **Encrypted Transit** - IPsec VPN encryption between clouds
- ✅ **High Availability** - Load balanced forwarding VMs
- ✅ **Snowflake Native** - Uses SPCS external access integration
- ✅ **Scalable** - Can handle multiple database connections

---

## Prerequisites

### Azure Requirements
- Azure subscription with appropriate permissions
- Azure Virtual Networks (2x recommended for separation)
- Azure VPN Gateway (VpnGw1 or higher)
- Ability to create Private Link Services
- Public IP addresses for VPN Gateway

### AWS Requirements
- AWS account with VPC access
- AWS VPN Gateway (Virtual Private Gateway)
- EC2 instance running MySQL
- Security Groups properly configured
- Non-overlapping CIDR blocks with Azure

### Snowflake Requirements
- Snowflake account with SPCS enabled
- Ability to create External Access Integrations
- Appropriate Snowflake roles and permissions

### Network Planning
- **Azure VNet 1 (Forwarding VMs):** e.g., 10.210.0.0/16
- **Azure VNet 2 (VPN Gateway):** e.g., 10.220.0.0/16
- **AWS VPC:** e.g., 10.230.0.0/16
- Ensure no CIDR overlap between networks

---

## Architecture Components

### 1. Azure Infrastructure

| Component | Purpose | Configuration Notes |
|-----------|---------|-------------------|
| **Private Link Service** | Snowflake Private Endpoint target | Must be in Standard SKU, requires Standard Load Balancer |
| **Standard Load Balancer** | Distributes traffic to forwarding VMs | Internal/Private, TCP health probes on MySQL port |
| **Forwarding VMs (x2)** | TCP proxy with HAProxy | Ubuntu with IP forwarding, HAProxy listening on 3306 |
| **NAT Gateway** | Outbound internet for VM updates | Optional but recommended for package management |
| **VPN Gateway** | Azure side of VPN tunnel | VpnGw1 or higher, requires Gateway subnet |
| **VNet Peering** | Connects VM VNet to Gateway VNet | Gateway transit enabled |

### 2. AWS Infrastructure

| Component | Purpose | Configuration Notes |
|-----------|---------|-------------------|
| **VPN Gateway** | AWS side of VPN tunnel | Virtual Private Gateway attached to VPC |
| **Customer Gateway** | Represents Azure VPN endpoint | Configured with Azure VPN Gateway public IP |
| **VPN Connection** | IPsec tunnel configuration | BGP or static routing, shared key required |
| **MySQL EC2 Instance** | Target database server | MySQL configured to listen on VPC network |
| **Security Groups** | Firewall rules | Allow MySQL port from Azure CIDR ranges |

### 3. Snowflake Components

| Component | Purpose | Configuration Notes |
|-----------|---------|-------------------|
| **External Access Integration** | Defines Private Endpoint connection | Points to Private Link Service alias |
| **Private Endpoint** | Snowflake-managed connection | Created automatically by Snowflake |
| **SPCS Container** | Application making database calls | Uses External Access Integration |

---

## Deployment Steps

### Phase 1: Azure Foundation

#### Step 1.1: Create Azure Resource Group
- Create a dedicated resource group for all resources
- Choose appropriate Azure region (same as Snowflake region recommended)

#### Step 1.2: Create Virtual Networks
- **VNet 1:** For forwarding VMs and Private Link Service
  - Create subnet for VMs (e.g., 10.210.1.0/24)
  - Enable Private Link Service network policies (disable protection)
- **VNet 2:** For VPN Gateway
  - Create GatewaySubnet (required name, e.g., 10.220.2.0/24)

#### Step 1.3: Deploy VPN Gateway
- Create public IP for VPN Gateway (Standard SKU, Static)
- Create VPN Gateway (VpnGw1 or higher)
- **Note:** Gateway creation takes 30-45 minutes

#### Step 1.4: Configure VNet Peering
- Peer VNet 1 to VNet 2
- Enable "Use Remote Gateway" on VNet 1
- Enable "Allow Gateway Transit" on VNet 2

---

### Phase 2: AWS Foundation

#### Step 2.1: Create or Verify AWS VPC
- Ensure VPC has non-overlapping CIDR with Azure
- Create subnet for MySQL EC2 instance
- Attach Internet Gateway (for EC2 public access during setup)

#### Step 2.2: Deploy MySQL EC2 Instance
- Launch Ubuntu or Amazon Linux instance
- Install and configure MySQL 8.0+
- **Critical:** Configure MySQL `bind-address = 0.0.0.0` in my.cnf
- Create database users with `'username'@'%'` for Azure access
- Enable `skip_name_resolve` in MySQL config (recommended)

#### Step 2.3: Configure Security Groups
- Allow inbound TCP port 3306 from Azure VNet CIDRs
- Allow SSH from your management IPs (for setup)
- Configure outbound rules as needed

#### Step 2.4: Create AWS VPN Gateway
- Create Virtual Private Gateway
- Attach to VPC
- Enable route propagation on VPC route tables

---

### Phase 3: Site-to-Site VPN

#### Step 3.1: Create AWS Customer Gateway
- Use Azure VPN Gateway public IP address
- Select routing type (BGP or Static)

#### Step 3.2: Create AWS VPN Connection
- Link Customer Gateway to Virtual Private Gateway
- Configure pre-shared key (strong, 8-128 characters)
- Download configuration for Azure

#### Step 3.3: Configure Azure Local Network Gateway
- Create Local Network Gateway pointing to AWS tunnel IP
- Specify AWS VPC CIDR ranges

#### Step 3.4: Create Azure VPN Connection
- Link Azure VPN Gateway to Local Network Gateway
- Use same pre-shared key from AWS
- Connection establishes automatically

#### Step 3.5: Verify VPN Connectivity
- Check connection status in Azure Portal: "Connected"
- Check AWS VPN status: Both tunnels "UP"
- Verify route propagation in AWS route tables
- Test ping from Azure VM to AWS EC2 private IP

---

### Phase 4: Azure Forwarding Layer

#### Step 4.1: Deploy Forwarding VMs
- Create 2x Ubuntu VMs (B1s/B2s sufficient for testing)
- Enable IP forwarding on NICs
- No public IPs needed (unless for management)
- Place in VNet 1 subnet

#### Step 4.2: Configure HAProxy on Each VM
- Install HAProxy package
- Configure TCP proxy mode
- Frontend: Listen on `0.0.0.0:3306`
- Backend: Point to AWS MySQL EC2 private IP:3306
- Enable health checks with `option tcp-check`
- Start and enable HAProxy service

**Example HAProxy Backend Configuration:**
```
backend mysql_backend
    mode tcp
    option tcp-check
    server aws_mysql <AWS_EC2_PRIVATE_IP>:3306 check inter 2000 rise 2 fall 3
```

#### Step 4.3: Configure Route Table
- Create route table for VM subnet
- Add route: Destination = AWS VPC CIDR, Next Hop = Virtual Network Gateway
- Associate route table with VM subnet

#### Step 4.4: Test Connectivity
- From forwarding VM: `nc -zv <AWS_EC2_IP> 3306`
- From forwarding VM: `mysql -h <AWS_EC2_IP> -u testuser -p`
- Verify HAProxy logs show successful backend connections

---

### Phase 5: Load Balancer & Private Link Service

#### Step 5.1: Create Standard Load Balancer
- **Type:** Internal (Private)
- **SKU:** Standard (required for Private Link Service)
- Frontend IP: Dynamic private IP in VM subnet

#### Step 5.2: Configure Backend Pool
- Add both forwarding VMs to backend pool
- Use VM NICs' IP configurations

#### Step 5.3: Configure Health Probe
- **Protocol:** TCP
- **Port:** 3306 (MySQL port)
- **Interval:** 15 seconds
- **Unhealthy threshold:** 2 consecutive failures

#### Step 5.4: Create Load Balancing Rule
- **Frontend port:** 3306
- **Backend port:** 3306
- **Protocol:** TCP
- Link to health probe
- Link to backend pool

#### Step 5.5: Verify Health Probes
- Check both VMs show as "Healthy" in backend pool
- Wait 30-60 seconds for probes to stabilize
- Check HAProxy logs for successful health checks

#### Step 5.6: Create Private Link Service
- Link to Load Balancer frontend IP configuration
- Configure NAT IP (auto-assign from subnet)
- **Visibility:** Set subscription IDs allowed to connect (Snowflake subscription)
- **Auto-approval:** Optional (can require manual approval)
- Note the **Private Link Service Alias** - needed for Snowflake

---

### Phase 6: Snowflake Integration

#### Step 6.1: Provision Private Endpoint in Snowflake

First, provision the Private Link endpoint using the Azure Private Link Service details:

```sql
-- Provision the Private Endpoint
SELECT SYSTEM$PROVISION_PRIVATELINK_ENDPOINT(
  '/subscriptions/<subscription_id>/resourceGroups/<resource_group>/providers/Microsoft.Network/privateLinkServices/<pls_name>',
  '<pls_alias>'
);
```

**Example:**
```sql
SELECT SYSTEM$PROVISION_PRIVATELINK_ENDPOINT(
  '/subscriptions/[...]/resourceGroups/rg-privatelink-q3y5j6/providers/Microsoft.Network/privateLinkServices/pls-service-q3y5j6',
  'pls-service-q3y5j6.[...].westeurope.azure.privatelinkservice'
);
```

**Where to find these values:**
- **Resource ID:** Azure Portal → Private Link Service → Properties → Resource ID
- **Alias:** Azure Portal → Private Link Service → Properties → Alias

#### Step 6.2: Create Network Rule

Create a network rule that references the Private Link Service alias with the MySQL port:

```sql
CREATE OR REPLACE NETWORK RULE <database>.<schema>.on_prem_mysql_rule
  MODE = EGRESS
  TYPE = PRIVATE_HOST_PORT
  VALUE_LIST = ('<pls_alias>:3306');
```

**Example:**
```sql
CREATE OR REPLACE NETWORK RULE <database>.<schema>.on_prem_mysql_rule
  MODE = EGRESS
  TYPE = PRIVATE_HOST_PORT
  VALUE_LIST = ('pls-service-q3y5j6.[...].westeurope.azure.privatelinkservice:3306');
```

**Important Notes:**
- Use `PRIVATE_HOST_PORT` type (not `HOST_PORT`) for Private Link connections
- Include the port `:3306` in the VALUE_LIST
- Use the full Private Link Service alias

#### Step 6.3: Create External Access Integration

Create the External Access Integration that uses the network rule:

```sql
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION on_prem_mysql_eai
  ALLOWED_NETWORK_RULES = (<database>.<schema>.on_prem_mysql_rule)
  ENABLED = true
  COMMENT = 'External Access Integration for on-prem access to MySQL';
```


#### Step 6.4: Grant Permissions

Grant usage on the integration to appropriate roles:

```sql
GRANT USAGE ON INTEGRATION on_prem_mysql_eai TO ROLE <your_role>;
```

#### Step 6.5: Approve Private Endpoint in Azure (if required)

In Azure Portal:
- Navigate to Private Link Service
- Check "Private endpoint connections"
- You should see a pending connection from Snowflake
- Approve the connection
- Wait for status to show "Approved"

**Note:** If you configured auto-approval in your Private Link Service, this step happens automatically.

#### Step 6.6: Test Connectivity from Snowflake

Test the connection from Snowflake:

Follow the Testing & Validation Notebook for MYSQL available here: https://github.com/Snowflake-Labs/sfguide-getting-started-with-openflow-spcs/blob/main/notebooks

---

## Validation & Testing

### End-to-End Connectivity Test

#### Level 1: AWS VPN Connectivity
```bash
# From Azure VM
ping <AWS_EC2_Private_IP>
```
**Expected:** Successful ping response

#### Level 2: MySQL Port Connectivity
```bash
# From Azure VM
nc -zv <AWS_EC2_Private_IP> 3306
```
**Expected:** Connection succeeded

#### Level 3: MySQL Authentication
```bash
# From Azure VM
mysql -h <AWS_EC2_Private_IP> -u testuser -p -e "SELECT 1;"
```
**Expected:** Query returns result

#### Level 4: HAProxy Forwarding
```bash
# From Azure VM (localhost)
mysql -h localhost -u testuser -p -e "SELECT 1;"
```
**Expected:** Query returns result through HAProxy

#### Level 5: Load Balancer
```bash
# From a machine in Azure VNet
mysql -h <Load_Balancer_IP> -u testuser -p -e "SELECT 1;"
```
**Expected:** Query returns result, load balanced between VMs

#### Level 6: Private Link
```bash
# From Snowflake SPCS container (notebook)
# Follow the Notebook
```
**Expected:** Query returns result through entire chain

---

## Network Security Considerations

### Azure Network Security Groups (NSGs)

**Forwarding VM NSG Rules:**
- **Inbound:**
  - Allow: Source = `AzureLoadBalancer`, Port = Any (for health probes)
  - Allow: Source = VNet CIDR, Port = 3306 (MySQL)
  - Allow: Source = Snowflake Private Endpoint, Port = 3306
- **Outbound:**
  - Allow: Destination = AWS VPC CIDR, Port = 3306

### AWS Security Groups

**MySQL EC2 Security Group:**
- **Inbound:**
  - Allow: Source = Azure VNet CIDR (10.210.0.0/16), Port = 3306
  - Allow: Source = Your management IPs, Port = 22 (SSH)
- **Outbound:**
  - Allow: Destination = 0.0.0.0/0, All ports (or restrict as needed)

### MySQL User Permissions

Create users with appropriate host patterns:

```sql
-- Allow from anywhere
CREATE USER 'appuser'@'%' IDENTIFIED BY 'secure_password';
GRANT SELECT, INSERT, UPDATE ON database.* TO 'appuser'@'%';

FLUSH PRIVILEGES;
```

**Recommendation:** Use `skip_name_resolve` in MySQL config to avoid hostname resolution issues.

---

## Troubleshooting Guide

### VPN Connection Issues

**Symptom:** Azure VPN status shows "Not Connected"

**Check:**
- Pre-shared keys match on both sides
- Azure Local Network Gateway has correct AWS tunnel IP
- AWS Customer Gateway has correct Azure VPN public IP
- NSG rules allow IPsec (UDP 500, 4500)

**Resolution:**
- Verify configuration, disconnect and reconnect VPN

---

### HAProxy Backend Down

**Symptom:** Health probes failing, backend marked as "DOWN"

**Check:**
```bash
# On forwarding VM
systemctl status haproxy
nc -zv <AWS_EC2_IP> 3306
tail -f /var/log/haproxy.log
```

**Common Causes:**
- VPN tunnel is down
- AWS security group blocking traffic
- MySQL not listening on 0.0.0.0
- Route table missing AWS CIDR route

---

### MySQL Access Denied

**Symptom:** "Host 'X' is not allowed to connect"

**Check:**
```sql
-- On MySQL server
SELECT User, Host FROM mysql.user WHERE User = 'youruser';
SHOW GRANTS FOR 'youruser'@'%';
```

**Resolution:**
- Ensure user exists with correct host pattern (`@'%'` or `@'10.210.%'`)
- Run `FLUSH PRIVILEGES;` after user changes
- Enable `skip_name_resolve` in my.cnf

---

### Load Balancer Health Probe Failures

**Symptom:** Backend VMs marked as "Unhealthy"

**Check:**
- HAProxy is running: `systemctl status haproxy`
- Port 3306 is listening: `ss -tlnp | grep 3306`
- NSG allows AzureLoadBalancer source
- HAProxy backend can reach MySQL

**View HAProxy Stats:**
```bash
echo "show stat" | socat stdio /run/haproxy/admin.sock
```

---

### Snowflake Private Endpoint Not Connecting

**Symptom:** Private Endpoint shows "Pending" or connection fails

**Check:**
- Private Link Service visibility includes Snowflake subscription
- Private Endpoint connection is approved in Azure

**Test from Azure side:**
```bash
# Check Private Endpoint connections
az network private-link-service show \
  --name <pls-name> \
  --resource-group <rg-name> \
  --query "privateEndpointConnections[*].{Name:name, Status:privateLinkServiceConnectionState.status}"
```

---

## Performance Considerations

### Latency Components

| Segment | Typical Latency | Notes |
|---------|----------------|-------|
| Snowflake → Private Endpoint | <1ms | Within same region |
| Private Endpoint → Load Balancer | <1ms | Same VNet |
| Load Balancer → HAProxy | <1ms | Local network |
| HAProxy → Azure VPN | 1-2ms | VNet peering |
| Azure VPN → AWS VPN | 20-50ms | Cross-cloud, varies by region |
| AWS VPN → MySQL EC2 | <1ms | VPC internal |
| **Total Round Trip** | **50-100ms** | Typical for cross-cloud |

### Optimization Tips

1. **Region Selection:** Co-locate Azure and AWS regions (e.g., Azure West Europe ↔ AWS eu-west-1)
2. **VPN Gateway SKU:** Higher SKUs provide better throughput
3. **VM Size:** Forwarding VMs can scale up if network throughput is bottleneck
4. **HAProxy Tuning:** Adjust timeout settings and connection pooling
5. **MySQL Optimization:** Use connection pooling, query optimization

### Capacity Planning

**Expected Throughput:**
- VpnGw1: Up to 650 Mbps
- VpnGw2: Up to 1 Gbps
- VpnGw3: Up to 1.25 Gbps

**Concurrent Connections:**
- HAProxy can handle thousands of concurrent connections per VM
- Scale horizontally by adding more forwarding VMs to backend pool

---

## Monitoring & Alerting

### Azure Metrics to Monitor

- **VPN Gateway:**
  - Tunnel ingress/egress bytes
  - Connection status
  - BGP route count (if using BGP)
  
- **Load Balancer:**
  - Health probe status
  - Data path availability
  - SNAT connection count

- **Forwarding VMs:**
  - CPU/Memory utilization
  - Network throughput
  - HAProxy connection count

### HAProxy Monitoring

**Stats Page:**
- Accessible at `http://<VM_IP>:8404/stats`
- Shows real-time connection counts, backend status
- Enable authentication for security

**Logs:**
```bash
sudo journalctl -u haproxy -f
```

### MySQL Monitoring

**Connection Tracking:**
```sql
SHOW PROCESSLIST;
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Connections';
```

---

## Cost Estimation (Monthly)

### Azure Costs
| Component | Quantity | Est. Cost (USD) |
|-----------|----------|-----------------|
| VPN Gateway (VpnGw1) | 1 | $140 |
| Standard Load Balancer | 1 | $25 |
| VMs (B1s) | 2 | $15-30 |
| NAT Gateway | 1 | $5 |
| Public IPs | 2-3 | $10 |
| Data Transfer (out) | Variable | $0.087/GB |
| **Subtotal** | | **~$195-210** |

### AWS Costs
| Component | Quantity | Est. Cost (USD) |
|-----------|----------|-----------------|
| VPN Connection | 1 | $36 |
| EC2 (t3.small) | 1 | $15-30 |
| Data Transfer (out) | Variable | $0.09/GB |
| **Subtotal** | | **~$51-66** |

**Total Monthly:** ~$250-280 (excluding data transfer)

---

## Security Best Practices

### 1. Network Isolation
- ✅ Use separate VNets for different functions
- ✅ No public IPs on forwarding VMs
- ✅ Private Link for Snowflake access
- ✅ VPN encryption for cross-cloud traffic

### 2. Access Control
- ✅ MySQL users with limited privileges
- ✅ Host-based MySQL authentication (`@'10.210.%'`)
- ✅ NSG/Security Group restrictions
- ✅ Private Link visibility controls

### 3. Secrets Management
- ✅ Store VPN pre-shared keys securely
- ✅ Rotate MySQL passwords regularly
- ✅ Use Snowflake secrets for database credentials
- ✅ Never commit credentials to version control

### 4. Monitoring & Auditing
- ✅ Enable Azure Network Watcher
- ✅ MySQL query logging (if required)
- ✅ HAProxy access logs
- ✅ VPN connection monitoring

### 5. High Availability
- ✅ Minimum 2 forwarding VMs
- ✅ Load balancer health probes
- ✅ Consider MySQL replication or RDS
- ✅ Automated VM backup/snapshots

---

## Frequently Asked Questions

### Q: Can I use Basic Load Balancer instead of Standard?
**A:** No. Private Link Service requires a Standard Load Balancer.

### Q: Do I need 2 forwarding VMs?
**A:** Recommended for high availability. You can start with 1 for testing but production should have at least 2.

### Q: Can I use AWS RDS instead of EC2 MySQL?
**A:** Yes! The architecture is the same. Point HAProxy backends to the RDS endpoint instead of EC2 IP.

### Q: What if Azure and AWS regions are far apart?
**A:** Latency will be higher (100-200ms). Choose closest region pairs or consider multi-region deployment.

### Q: Can multiple Snowflake accounts use this?
**A:** Yes. Each Snowflake account creates its own Private Endpoint to the shared Private Link Service.

### Q: How do I scale for more connections?
**A:** Add more forwarding VMs to the backend pool or upgrade VM SKUs for higher network throughput.

### Q: Is the VPN connection always on?
**A:** Yes, it's a persistent Site-to-Site connection, automatically maintained by both cloud providers.

### Q: What about costs for Snowflake Private Link?
**A:** Snowflake charges for Private Link data transfer. Consult Snowflake pricing for details.

---

## Support & Resources

### Azure Documentation
- [Private Link Service](https://docs.microsoft.com/azure/private-link/private-link-service-overview)
- [VPN Gateway](https://docs.microsoft.com/azure/vpn-gateway/)
- [Standard Load Balancer](https://docs.microsoft.com/azure/load-balancer/)

### AWS Documentation
- [VPN Connections](https://docs.aws.amazon.com/vpn/)
- [Virtual Private Gateway](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPC_VPN.html)
- [EC2 Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)

### Snowflake Documentation
- [External Access Integration](https://docs.snowflake.com/en/sql-reference/sql/create-external-access-integration)
- [SPCS Network Rules](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/additional-considerations-services#network-rules)
- [Private Connectivity](https://docs.snowflake.com/en/user-guide/admin-security-privatelink)

### HAProxy Documentation
- [HAProxy Documentation](https://www.haproxy.org/documentation.html)
- [TCP Mode Configuration](https://www.haproxy.com/blog/haproxy-configuration-basics-load-balance-your-servers/)

---

## Conclusion

This architecture provides a secure, scalable, and reliable method for Snowflake SPCS containers to access AWS MySQL databases through Azure Private Link and Site-to-Site VPN. The multi-layered approach ensures high availability, security, and performance for enterprise workloads.

### Key Takeaways

1. **Security First:** All traffic remains private with no public internet exposure
2. **High Availability:** Load balancer with multiple forwarding VMs ensures reliability
3. **Proven Technology:** Uses standard Azure and AWS networking features
4. **Snowflake Integration:** Native support through External Access Integrations
5. **Cross-Cloud:** Demonstrates enterprise-grade multi-cloud connectivity

### Next Steps

1. Review your specific requirements and adjust CIDR blocks
2. Gather necessary credentials and permissions
3. Follow the deployment phases in order
4. Test thoroughly at each level before proceeding
5. Document your specific configuration for future reference

For questions or support during implementation, consult your cloud architects, or contact your organization's support teams.
