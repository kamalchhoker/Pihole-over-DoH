# Pi-hole over DoH (DNS over HTTPS)

Network DNS queries can be transmitted either in plain text (via port 53) or inside secure packets (via HTTPS). Because Pi-hole lacks native support for DNS over HTTPS (DoH), alternative methods must be used to secure your upstream traffic.

---

## Option 1: Implement DoH via Local Reverse Proxy

This method uses a local service to act as a reverse proxy, accepting plain text queries from Pi-hole and forwarding them securely to public DoH providers.

### Method A: Using `dnscrypt-proxy`

1. **Install the service:**
   ```bash
   sudo apt update && sudo apt install dnscrypt-proxy
   ```
2. **Configure the service:** 
   Edit the `/etc/dnscrypt-proxy/dnscrypt-proxy.toml` file to enable DoH servers and ensure the service listens on a local port (e.g., `127.0.0.1:5053`).
3. **Verify the configuration:**
   ```bash
   sudo systemctl status dnscrypt-proxy
   ```

> [!WARNING]
> **Note:** This method is being phased out in newer documentation and repository releases in favor of other lightweight utilities.

### Method B: Using `cloudflared` Service

This method configures the Cloudflare Tunnel client on your Raspberry Pi to handle secure DNS queries.

1. **Install and run the script:** (https://github.com/deeprooter/DNS-over-DoH/blob/main/piholeoverDoH.sh).
2. **Configure Pi-hole Upstream DNS:** In the Pi-hole GUI, disable default providers and add your local proxy under **Custom 1 (IPv4)**:
   ```text
   127.0.0.1#5053
   ```
   (https://github.com/deeprooter/DNS-over-DoH/blob/main/DoH.png)
3. **Restart the DNS service:** Apply changes by running:
   ```bash
   sudo systemctl restart pihole-FTL
   ```

> [!CAUTION]
> **Important Considerations:**
> 1. The `proxy-dns` command structure is being phased out in newer releases of `cloudflared`, which may require updated configuration syntax.
> 2. Always verify the `cloudflared` Debian package architecture compatibility (e.g., ARMv7 vs. ARM64) with your specific Raspberry Pi hardware before installation.

---

## Option 2: Upstream Gateway Encryption (Foolproof Method)

Instead of forcing your primary local DNS servers to generate encrypted queries directly, route them through a dedicated third DNS server acting as a secure upstream gateway. 

Plain text queries are collected centrally by your primary Pi-holes, which then forward them to an AdGuard Home instance. The AdGuard Home instance encrypts the queries before sending them to public DNS providers.

> [!NOTE]
> You must own a valid domain name to successfully implement and secure this architecture.

### Network Architecture

```text
[ Home Devices ]
       │
       │ (Port 53 - Plain Text Queries)
       ▼
[ 2x Pi-hole DNS Servers ]
       │
       │ (Port 53 - Plain Text Upstream Forward)
       ▼
[ AdGuard Home / Gateway ]
       │
       │ (Port 443 - Encrypted DoH)
       ▼
[ Public DNS Providers (Cloudflare/Google) ]
```
## Steps to Implement This Concept

### 1. Prerequisites

*   **Domain Name:** Required to generate an API token (e.g., registered via Cloudflare).
*   **Docker:** Installed on your host system (see the [Docker Getting Started Guide](https://www.docker.com/get-started/)).
*   **Dockhand:** Recommended (but optional) tool to manage your Docker containers and YAML stack files ([Dockhand Releases](https://github.com/Finsys/dockhand/releases)).
*   **AdGuard Home:** Container deployed via Docker (conveniently found in the Dockhand built-in stacks).

---

### 2. Install Native Certbot on the Host

To bypass potential Docker registry issues, install Certbot natively on the host system along with the Cloudflare DNS plugin:

```bash
sudo apt update && sudo apt install certbot python3-certbot-dns-cloudflare -y
```

---

### 3. Configure Cloudflare API Credentials

Create a secure directory and store your Cloudflare API token so Certbot can automatically authenticate DNS challenges:

```bash
# Create a hidden directory for secrets
mkdir -p ~/.secrets/certbot/

# Create and edit the configuration file
nano ~/.secrets/certbot/cloudflare.ini
```

Paste the following line inside the `cloudflare.ini` file, replacing the placeholder with your actual token:

```ini
dns_cloudflare_api_token = YOUR_CLOUDFLARE_API_TOKEN_HERE
```

Restrict file permissions so only your user can read it:

```bash
chmod 600 ~/.secrets/certbot/cloudflare.ini
```

---

### 4. Request the Let's Encrypt Wildcard Certificate

Run Certbot to request a certificate covering your base domain and all subdomains using the DNS-01 challenge:

```bash
sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini \
  -d "*.kamalkc.cc" \
  -d "kamalkc.cc" \
  --preferred-challenges dns \
  --email halides@live.com \
  --agree-tos \
  --no-eff-email
```

> [!TIP]
> **Note:** Remember to replace `kamalkc.cc` and the email address with your own domain credentials. 
> 
> Upon successful completion, Certbot will display a message confirming where your new certificate and chain files are saved on the host.
<img width="1065" height="292" alt="20260716_21h59m54s_grim" src="https://github.com/user-attachments/assets/e0da320a-1824-45cd-aaaf-22f774ce99fa" />

---

### 5. Mount Certificate Volume to AdGuard Home

Edit your standalone `docker-compose.yml` file or update the stack configuration inside the Dockhand UI. You must mount the host's Let's Encrypt directory into the AdGuard container as a read-only volume:

```yaml
volumes:
  - /etc/letsencrypt:/opt/adguardhome/ssl:ro
```

<img width="722" height="522" alt="20260716_22h08m24s_grim" src="https://github.com/user-attachments/assets/6a4641e9-e28e-4f37-8231-de877836a8e4" />


---

### 6. Update AdGuard Encryption Settings

1. Log into your AdGuard Home dashboard.
2. Navigate to **Settings** > **Encryption settings**.
3. Enable encryption and enter the following mapped internal container paths:

*   **Paths to Certificate:** `/opt/adguardhome/ssl/live/kamalkc.cc/fullchain.pem`
*   **Paths to Private Key:** `/opt/adguardhome/ssl/live/kamalkc.cc/privkey.pem`

<img width="722" height="622" alt="20260716_22h03m51s_grim" src="https://github.com/user-attachments/assets/52cdfabb-5534-40f8-b4e9-4246051145dc" />


---

### 7. Verification Logs & Test Results
<img width="1237" height="1257" alt="20260716_20h44m57s_grim" src="https://github.com/user-attachments/assets/da58521a-564a-4816-ab39-bbc20ab95b91" />
