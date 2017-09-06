# ACME DNS-01 for Ubiquiti EdgeRouter

This repository is heavily based on [https://github.com/j-c-m/ubnt-letsencrypt/](https://github.com/j-c-m/ubnt-letsencrypt/). It's a simpler version to generate and automatically renew SSL certificate from [Let's Encrypt](https://letsencrypt.org/) without reconfiguring firewall and exposing any port to the internet. This is beneficial especially in restricted network (behind firewall or double NAT) or non-available required ports (i.e., 80, 443 - used by other services).

It does require DNS API access from the DNS provider. The list of supported DNS provider can be found from [acme.sh wiki page](https://github.com/Neilpang/acme.sh#9-automatic-dns-api-integration).

## Requirements

1. Determine required scripts

	First, you need to validate if your DNS provider is supported by [acme.sh dnsapi](https://github.com/Neilpang/acme.sh/tree/master/dnsapi). To minimize the space needed, you only need to install the corresponding API script to your router. For example, GoDaddy only needs `dns_gd.sh`.

2. Obtain API login information from DNS provider

	Follow the instruction from [acme.sh dnsapi](https://github.com/Neilpang/acme.sh/tree/master/dnsapi) to get your API login information. Also take note the required tags, e.g., `GD_Key` and `GD_Secret` for GoDaddy.

## Install scripts

You'll install `acme.sh`, `renew.acme.sh`, `reload.acme.sh`, and coresponding DNS API script. The scripts assume that `acme.sh` is put in `/config/scripts/acme`. If you decide to use different folder, you'll need to modify the `renew.acme.sh` to reflect the change.

```
mkdir -p /config/scripts/acme/dnsapi
curl -o /config/scripts/acme/acme.sh https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh
curl -o /config/scripts/renew.acme.sh https://raw.githubusercontent.com/hungnguyenm/edgemax-acme/master/renew.acme.sh
curl -o /config/scripts/reload.acme.sh https://raw.githubusercontent.com/hungnguyenm/edgemax-acme/master/reload.acme.sh
curl -o /config/scripts/acme/dnsapi/[yourdnsapi].sh https://raw.githubusercontent.com/Neilpang/acme.sh/master/dnsapi/[yourdnsapi].sh
chmod 755 /config/scripts/acme/acme.sh /config/scripts/renew.acme.sh /config/scripts/reload.acme.sh /config/scripts/acme/dnsapi/[yourdnsapi].sh
```

## Request certificate the first time

`renew.acme.sh` requires the following options:
- `-d` is the domain to issue certificate. You can add multiple domains by repeating this option.
- `-n` is the DNS provider id. It is the same with your DNS API script from [acme.sh dnsapi](https://github.com/Neilpang/acme.sh/tree/master/dnsapi).
- `-t` is the corresponding API tag. For example, `GD_Key` and `GD_Secret` for GoDaddy.
- `-k` is the corresponding value for API tag. The number of `-t` and `-k` must be the same, and tag/key are matched based on index.

The command below works for GoDaddy DNS:
```
sudo /config/scripts/renew.acme.sh -d subdomain.example.com -n dns_gd -t "GD_Key" -t "GD_Secret" -k "sdfsdfsdfljlbjkljlkjsdfoiwje" -k "asdfsdafdsfdsfdsfdsfdsafd"
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

If the management UI is accessible with the new valid certificte, you're ready to schedule task for automatic renewing certificate.

```
set system task-scheduler task renew.acme executable path /config/scripts/renew.acme.sh
set system task-scheduler task renew.acme interval 15d
set system task-scheduler task renew.acme executable arguments '-d subdomain.example.com -n dns_gd -t &quot;GD_Key&quot; -t &quot;GD_Secret&quot; -k &quot;sdfsdfsdfljlbjkljlkjsdfoiwje&quot; -k &quot;asdfsdafdsfdsfdsfdsfdsafd&quot;'
```

Remember to update the arguments according to your previous run configuration, and replace any quote with `&quot;`