# Pihole over DoH (HTTPS)
DNs queries in the network could be transmiited either in plain text (via HTTP) or into secure packerts (via HTTPS). Pihole based DNS serveres lacks native support of DNS over HTTPS hence there are alternate ways to achive this.

Option 1:
Implement DoH via dnscrypt-proxy or using Cloudflared service.
Both methods provides a revrese proxy and generates secure DNs queries.
Via dnscrypt-proxy

To implement DNS over HTTPS (DoH) using dnscrypt-proxy, install it with sudo apt install dnscrypt-proxy, configure the dnscrypt-proxy.toml file to use DoH servers, and ensure it listens on a local port like 5053. 
Verify configuration sudo systemctl status dnscrypt-proxy

Note: his method is being phased out in newer releases

Via Cloudflared service on DNS server

The script will configure Cloudflared service on your raspverry pi and start it. Once the script runs sucessfullt the last step is to add your custom DNS configured.
Following will be the entry instead of upstream DNS: 127.0.0.1#5053
See the snapshot to add the DNS enty in pihole GUI.
Run the following command in the terminal to restart the pihole with updated setting: sudo systemctl restart pihole-FTL
Note: 1. proxy-dns command is being phased out in newer releases of Cloudflared, which leads this method outdated.
      2. Verify the cloudflared debain package compatibility with your Raspberry Pi hardware before opting in this method.

Option 2: (full-proof)
Instead of forcing the local DNS serveres generating the encrypted queries use a third DNS server which will work as an upstream DNS server. Plain text queries will be received from DNS1 and DNS2, while DNS3 will encrypt the queries before sending them to publick DNS serviers for the resolution.
Note: you will need to have a valid domain name to move forward with this method.

[Home Devices] 
      │ (Port 53 - Plain text)
      ▼
[ 2x Pi-hole/ DNS servers ] 
      │ (Port 53 - Plain text upstream forward)
      ▼
[ AdGuard Home (Docker) ] ──(Bootstrap lookups to 1.1.1.1/9.9.9.10)
      │ 
      ├─► Natively reads Let's Encrypt Wildcard Certificates (*.kamalkc.cc)
      │ 
      ▼ (Port 443 - Fully Encrypted DNS-over-HTTPS / DoH)
[ Public Internet ]

Steps to Impment this concept:
1. Prerequsites:
   Docker (https://www.docker.com/get-started/)
   Dockhand (https://github.com/Finsys/dockhand/releases) Not required but recomnded to manage the docker container and yml files.

   
