# AWS VPC Peering Lab - Screenshot Capture Guide

This guide outlines the exact screenshots required for your final lab submission. Each screenshot must be clear, legible, and include your resource names, IDs, and tags where applicable.

---

## Required Screenshots Checklist

| ID | Required View / Command | File Name | Acceptance Criteria |
|---|---|---|---|
| **01** | AWS VPC Console: Subnet Associations & Routes for VPC A | `01_vpc_a_subnets_routes.png` | Shows `ewb-rt-a-public` associated with `ewb-a-public` having `0.0.0.0/0 -> igw` AND `ewb-rt-a-private` associated with `ewb-a-private` having ONLY local route initially. |
| **02** | AWS EC2 Console: Instances Inventory | `02_ec2_instances_inventory.png` | Shows all 3 instances running (`ewb-bastion`, `ewb-app-a`, `ewb-app-b`). Bastion has a Public IPv4; App-A and App-B have NO public IP (field empty or `-`). |
| **03** | AWS VPC Console: Peering Connection Active | `03_peering_active.png` | Shows peering connection `ewb-a-b-peer` in status **Active**, with Requester `ewb-vpc-a` (10.10.0.0/16) and Accepter `ewb-vpc-b` (10.20.0.0/16). |
| **04** | AWS VPC Console: Route Tables Peering Routes | `04_route_tables_peering.png` | Displays routes for all 3 route tables: `ewb-rt-a-public` (`10.20.0.0/16 -> pcx`), `ewb-rt-a-private` (`10.20.0.0/16 -> pcx`), and `ewb-rt-b-private` (`10.10.0.0/16 -> pcx`). |
| **05** | Terminal: Test 01 - Baseline Failure | `05_baseline_ping_failure.png` | On `ewb-app-a`, run: `ping -c 4 10.20.1.10`. Must show **100% packet loss / Destination Host Unreachable** before peering routes are created. |
| **06** | Terminal: Test 02 - Forward Path Success | `06_forward_ping_success.png` | On `ewb-app-a`, run: `hostname; hostname -I; ping -c 4 10.20.1.10`. Must show **4 packets transmitted, 4 received, 0% packet loss**. |
| **07** | Terminal: Test 03 - Reverse Path Success | `07_reverse_ping_success.png` | On `ewb-app-b`, run: `hostname; hostname -I; ping -c 4 10.10.2.10`. Must show **4 packets transmitted, 4 received, 0% packet loss**. |
| **08** | Terminal: Test 04 - Private SSH via Bastion | `08_ssh_app_b_proxyjump.png` | On your local workstation, run: `ssh ewb-app-b`. Show direct login prompt dropping into `[ec2-user@ip-10-20-1-10 ~]$` via ProxyJump. |
| **09** | Terminal & Console: Controlled Failure & Recovery | `09_controlled_failure_recovery.png` | Show failure when inbound ICMP rule on `ewb-sg-app-b` is temporarily removed (`100% packet loss`), followed by successful ping once rule is restored (`0% packet loss`). |
| **10** | AWS EC2 / VPC Console: Clean-up Evidence | `10_cleanup_verification.png` | Shows all lab instances terminated, peering connection deleted, custom route tables and subnets removed, and VPCs deleted to ensure 0 extra AWS charges. |

---

## Screenshot Best Practices
1. **Highlighting**: Use red or green boxes to draw attention to status flags (`Active`, `running`, `0% packet loss`).
2. **Terminal Clarity**: Run `hostname` and `hostname -I` immediately preceding ping commands so evaluators can verify the execution context.
3. **No Private Secrets**: Never include private keys (`.pem`), passwords, AWS Secret Access Keys, or temporary session tokens in any screenshot.
