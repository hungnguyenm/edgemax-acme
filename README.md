# ACME DNS-01 for Ubiquiti EdgeRouter

This repository is heavily based on [https://github.com/j-c-m/ubnt-letsencrypt/](https://github.com/j-c-m/ubnt-letsencrypt/). It's a simpler version to generate and automatically renew SSL certificate from [Let's Encrypt](https://letsencrypt.org/) without reconfiguring firewall and exposing any port to the internet. This is beneficial especially in restricted network (behind firewall or double NAT) or non-available required ports (i.e., 80, 443 - used by other services).

It does require DNS API access from the DNS provider. The list of supported DNS provider can be found from [acme.sh wiki page](https://github.com/Neilpang/acme.sh#9-automatic-dns-api-integration).

## Requirements

1. Determine required scripts

	First, you need to validate if your DNS provider is supported by [acme.sh dnsapi](https://github.com/Neilpang/acme.sh/tree/master/dnsapi). To minimize the space needed, you only need to install the corresponding API script to your router. For example, GoDaddy only needs `dns_gd.sh`.

2. Obtain API login information from DNS provider

	Follow the instruction from [acme.sh dnsapi](https://github.com/Neilpang/acme.sh/tree/master/dnsapi) to get your API login information. Also take note the required tags, e.g., `GD_Key` and `GD_Secret` for GoDaddy.

## Install scripts

You'll install `acme.sh`, `renew.acme.sh`, `reload.acme.sh`, and the corresponding DNS API script. The scripts assume that `acme.sh` is put in `/config/scripts/acme`. If you decide to use different folder, you'll need to modify the `renew.acme.sh` to reflect the change.

```
mkdir -p /config/scripts/acme/dnsapi
curl -o /config/scripts/acme/acme.sh https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh
curl -o /config/scripts/renew.acme.sh https://raw.githubusercontent.com/hungnguyenm/edgemax-acme/master/renew.acme.sh
curl -o /config/scripts/reload.acme.sh https://raw.githubusercontent.com/hungnguyenm/edgemax-acme/master/reload.acme.sh
curl -o /config/scripts/acme/dnsapi/[yourdnsapi].sh https://raw.githubusercontent.com/Neilpang/acme.sh/master/dnsapi/[yourdnsapi].sh
chmod 755 /config/scripts/acme/acme.sh /config/scripts/renew.acme.sh /config/scripts/reload.acme.sh /config/scripts/acme/dnsapi/[yourdnsapi].sh
```

Remember to replace `[yourdnsapi]` with your DNS provider script file name from above.

## Request certificate the first time

`renew.acme.sh` requires the following options:
- `-d` (required) is the domain to issue certificate. You can add multiple domains by repeating this option.
- `-n` (required) is the DNS provider id. It is the same with your DNS API script from [acme.sh dnsapi](https://github.com/Neilpang/acme.sh/tree/master/dnsapi).
- `-t` (required) is the corresponding API tag. For example, `GD_Key` and `GD_Secret` for GoDaddy.
- `-k` (required) is the corresponding value for API tag. The number of `-t` and `-k` must be the same, and tag/key are matched based on index.
- `-i` (optional) flag to enable insecure mode.
- `-v` (optional) flag to enable acme verbose.

As ACME now prevents `acme.sh` to be called with sudo, we'd need to switch to root user before running the script the first time:
```
sudo su
```

With the root shell, the command below works for GoDaddy DNS:
```
/config/scripts/renew.acme.sh -d subdomain.example.com -n dns_gd -t "GD_Key" -t "GD_Secret" -k "sdfsdfsdfljlbjkljlkjsdfoiwje" -k "asdfsdafdsfdsfdsfdsfdsafd"
```

If you need extra arguments to acme.sh (perhaps for a [challenge alias](https://github.com/Neilpang/acme.sh/wiki/DNS-alias-mode)) specify them at the end after a ```--```:
```
/config/scripts/renew.acme.sh -d subdomain.example.com -n dns_gd -t "GD_Key" -t "GD_Secret" -k "sdfsdfsdfljlbjkljlkjsdfoiwje" -k "asdfsdafdsfdsfdsfdsfdsafd" -- --challenge-alias challenge-domain.example.com
```

## Configure router

1. Set domain pointing to router internal IP address

	You can configure in two ways (assuming internal IP address is 192.168.1.1):

	* router static host mapping: `set system static-host-mapping host-name subdomain.example.com inet 192.168.1.1`
	* domain A record: depends on DNS provider, you can add an A record to the DNS database

2. Enable configuration mode

	Login to router CLI, then

	```
	configure
	```

3. Set cert-file location for management UI

	```
	set service gui cert-file /config/ssl/server.pem
	```

4. Commit and save your configuration

	```
	commit
	save
	```

	You should be able to access your router at [https://subdomain.example.com](https://subdomain.example.com). Verify if the certificate is trusted.

## Configure automatic renew

If the management UI is accessible with the new valid certificate, you're ready to schedule task for automatic renewing certificate. The following commands create a cronjob to execute `renew.acme.sh` every day, with the same arguments that we run earlier. Since `acme.sh` script only renews cert every 60 days, this task will just quit within the first 60 days. At the time this guide is written, all Let's Encrypt certificates expire after 90 days.

```
set system task-scheduler task renew.acme executable path /config/scripts/renew.acme.sh
set system task-scheduler task renew.acme interval 1d
set system task-scheduler task renew.acme executable arguments '-d subdomain.example.com -n dns_gd -t GD_Key -t GD_Secret -k sdfsdfsdfljlbjkljlkjsdfoiwje -k asdfsdafdsfdsfdsfdsfdsafd'
```

## Changelog

```
2020-01-17: Update the first-time command to fix sudo error from acme.sh
2018-09-14: Add an option for providing arbitrary arguments to acme.sh
2018-04-22: Change RSA certificate to ECDSA P-384; Set default log to /var/log/acme.log
2017-12-21: Add -i and -v options in renew.acme.sh
2017-12-02: Remove &quot; in task-scheduler arguments
```
