# Pihole-over-DoH
The script will configure Cloudflared service on your raspverry pi and start it. Once the script runs sucessfullt the last step is to add your custom DNS configured.
Following will be the entry instead of upstream DNS: 127.0.0.1#5053
See the snapshot to add the DNS enty in pihole GUI.
Run the following command in the terminal to restart the pihole with updated setting: sudo systemctl restart pihole-FTL
