# AWS VPC Peering - Viva & Technical Interview

This document provides comprehensive, expert-level explanations for the four mandatory workbook defense questions and advanced architectural considerations.

---

### Question 1: Why is the return route needed?

**Comprehensive Answer:**
IP routing is fundamentally **hop-by-hop and asymmetrical**. Network routers make forwarding decisions independently in each direction based solely on their own local routing tables:

1. **Forward Path ($A 	o B$):** When `ewb-app-a` (`10.10.2.10`) transmits an IP packet destined for `10.20.1.10`, the AWS VPC router consults `ewb-rt-a-private`. Because of the route entry `10.20.0.0/16 -> pcx-xxxx`, the packet is routed across the peering connection into VPC B and delivered to `ewb-app-b`.
2. **Reverse/Return Path ($B 	o A$):** When `ewb-app-b` receives an ICMP Echo Request or a TCP SYN packet, its operating system kernel must generate a response (ICMP Echo Reply or TCP SYN-ACK) with destination `10.10.2.10`.
3. **The Black Hole Problem:** The virtual router for VPC B consults `ewb-rt-b-private`. If `ewb-rt-b-private` does **not** contain an explicit route targeting `10.10.0.0/16 -> pcx-xxxx`, the packet matches no valid route (since VPC B has only its local route `10.20.0.0/16` and no Internet Gateway). Consequently, the packet is silently discarded (black-holed) by the VPC router.

> **Key Takeaway:** A bidirectional communication session requires bidirectional routing. Establishing the peering link creates the physical/logical pathway, but each VPC's route table independently dictates whether traffic can enter that pathway.

---

### Question 2: Why is the App-B SSH source the bastion private IP?

**Comprehensive Answer:**
When connecting from your workstation to `ewb-app-b` using OpenSSH `ProxyJump` (`ssh -J ec2-user@BASTION_IP ec2-user@10.20.1.10`):

1. **ProxyJump Mechanism:** The client SSH program on your laptop first establishes an encrypted SSH transport session to the bastion (`ewb-bastion`) on its public IP.
2. **Direct TCP Port Forwarding:** Once authenticated, the SSH client requests the bastion daemon to open an outbound TCP socket to the destination: `10.20.1.10:22`.
3. **Source IP Binding:** The bastion's operating system kernel creates this standard Layer-4 TCP connection from its own primary network interface (`eth0`, private IP `10.10.1.10`).
4. **No NAT Translation:** The bastion is not acting as a NAT gateway (which would translate external IPs); it is acting as an application-level SSH proxy.
5. **App-B Perspective:** When the TCP SYN packet arrives at `ewb-app-b`, the IP header source address is `10.10.1.10`. Therefore, `ewb-sg-app-b` must permit inbound TCP port 22 from `10.10.1.10/32` (the bastion's private IP), rather than your workstation's home IP.

---

### Question 3: Why does Active peering not guarantee a successful ping?

**Comprehensive Answer:**
An "Active" peering connection represents only that the two VPCs have agreed to establish a Layer-3 peering relationship. For end-to-end ICMP ping traffic to succeed, four distinct and independent architectural layers must be satisfied:

1. **Subnet Route Tables:** Both the source subnet route table (`ewb-rt-a-private`) and destination subnet route table (`ewb-rt-b-private`) must contain explicit route entries pointing to the peering ID (`pcx-xxxx`).
2. **Security Groups (Stateful):** The destination instance security group (`ewb-sg-app-b`) must explicitly allow inbound **ICMP IPv4 Echo Request (Type 8, Code 0)** from the source IP (`10.10.2.10/32`). (Note: Outbound replies are tracked statefully).
3. **Network Access Control Lists (NACLs - Stateless):** Both VPCs' NACLs must permit outbound and inbound traffic on ICMP and ephemeral return ports. Custom NACLs that block ephemeral ports or return traffic will break communication even with active peering.
4. **Target OS Firewall & Configuration:** The operating system kernel on the target instance must have ICMP response enabled (`net.ipv4.icmp_echo_ignore_all = 0`) and any host firewalls (e.g., `iptables`, `nftables`, `ufw`) must not drop ICMP.

---

### Question 4: Can VPC B use VPC A's internet gateway over peering?

**Comprehensive Answer:**
**No.** AWS VPC Peering is strictly **non-transitive** and does not support **edge-to-edge routing**.

- **AWS Architectural Restriction:** AWS explicitly prevents traffic from entering a VPC via a peering connection and exiting that same VPC through an Internet Gateway, NAT Gateway, AWS Site-to-Site VPN, or AWS Direct Connect connection.
- **Transitivity Breakdown:** VPC B $	o$ VPC A $	o$ Internet is transitive routing. In AWS VPC Peering, traffic can only originate in one VPC and terminate inside the peered VPC.
- **Enterprise Solution:** If an organization requires centralized egress or transitive routing among multiple VPCs, they must deploy an **AWS Transit Gateway (TGW)** or an egress VPC architecture with a centralized Network Firewall / NAT Gateway pool.

---

### Core Concepts Summary Table

| Concept | VPC Peering Behavior | Transit Gateway Alternative |
|---|---|---|
| **Topology** | Point-to-point (mesh required for $>2$ VPCs) | Hub-and-spoke centralized router |
| **Transitive Routing** | Unsupported (A-B + A-C $
e$ B-C) | Fully supported |
| **Edge-to-Edge Routing**| Blocked by AWS architecture | Supported (Centralized Internet / Direct Connect) |
| **Latency & Bandwidth** | Lowest possible (No bandwidth bottleneck, AWS backbone) | Very low, but subject to TGW processing pricing |
| **Maximum MTU** | 9001 bytes (Jumbo frames within same region) | 8500 bytes |
