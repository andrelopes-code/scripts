import subprocess


ad_dhcp = 'ad-dhcp.sh'
firewall = 'firewall.sh'
allshfiles = (ad_dhcp, firewall)


print("\033[1;33mEscolha os valores com atencao!")
# Definindo variaveis Gerais
print("\033[1;35mConfiguracoes GERAIS:\033[1;32m")
NEW_INTERFACE_INTERNA = input('interface interna: ').strip()
NEW_INTERFACE_EXTERNA = input('interface externa: ').strip()
NEW_DOMAIN = input('dominio: ').strip()
DOMAINUP = NEW_DOMAIN.upper()
NEW_NETWORK = input('ip da rede: ').strip()
NEW_NETMASK = input('mascara: ').strip()
NEW_GATEWAY = input('gateway: ').strip()
NEW_BROADCAST = input('broadcast: ').strip()
# Definindo variaveis do Firewall
print("\033[1;35mConfiguracoes FIREWALL:\033[1;32m")
IP_FIREWALL = input('IP: ').strip()
HOSTNAME_FIREWALL = input('hostname: ').strip()
# Definindo variaveis do AD-DHCP
print("\033[1;35mConfiguracoes AD-DHCP:\033[1;32m")
IP_AD = input('IP: ').strip()
HOSTNAME_AD = input('hostname: ').strip()
NEW_RANGE = input('Range [x.x.x.x x.x.x.x]: ').strip()
NEW_NAMESERVERS = input('Nameservers [ns1, ns2, ns3]: ').strip()


def general_change() -> None:
    subprocess.run(('sed', '-i', 's/INTERFACE_INTERNA=\".*\"/INTERFACE_INTERNA=\"{}\"/'.format(NEW_INTERFACE_INTERNA), *allshfiles))
    subprocess.run(('sed', '-i', 's/INTERFACE_EXTERNA=\".*\"/INTERFACE_EXTERNA=\"{}\"/'.format(NEW_INTERFACE_EXTERNA), *allshfiles))
    subprocess.run(('sed', '-i', 's/DOMAIN=\".*\"/DOMAIN=\"{}\"/'.format(NEW_DOMAIN), *allshfiles))
    subprocess.run(('sed', '-i', 's/NETMASK=\".*\"/NETMASK=\"{}\"/'.format(NEW_NETMASK), *allshfiles))
    subprocess.run(('sed', '-i', 's/GATEWAY=\".*\"/GATEWAY=\"{}\"/'.format(NEW_GATEWAY), *allshfiles))
    subprocess.run(('sed', '-i', 's/BROADCAST=\".*\"/BROADCAST=\"{}\"/'.format(NEW_BROADCAST), *allshfiles))
    subprocess.run(('sed', '-i', 's/NETWORK=\".*\"/NETWORK=\"{}\"/'.format(NEW_NETWORK), *allshfiles))


def firewall_change() -> None:
    subprocess.run(('sed', '-i', 's/IP_ADDRESS=\".*\"/IP_ADDRESS=\"{}\"/'.format(IP_FIREWALL), firewall))
    subprocess.run(('sed', '-i', 's/HOSTNAME=\".*\"/HOSTNAME=\"{}\"/'.format(HOSTNAME_FIREWALL), firewall))


def ad_dhcp_change() -> None:
    subprocess.run(('sed', '-i', 's/IP_ADDRESS=\".*\"/IP_ADDRESS=\"{}\"/'.format(IP_AD), ad_dhcp))
    subprocess.run(('sed', '-i', 's/HOSTNAME=\".*\"/HOSTNAME=\"{}\"/'.format(HOSTNAME_AD), ad_dhcp))
    subprocess.run(('sed', '-i', 's/DOMAINUP=\".*\"/DOMAINUP=\"{}\"/'.format(DOMAINUP), ad_dhcp))
    subprocess.run(('sed', '-i', 's/RANGE=\".*\"/RANGE=\"{}\"/'.format(NEW_RANGE), ad_dhcp))
    subprocess.run(('sed', '-i', 's/NAMESERVERS=\".*\"/NAMESERVERS=\"{}\"/'.format(NEW_NAMESERVERS), ad_dhcp))


def files_change() -> None:
    # firewall
    subprocess.run(('sed', '-i', 's/localnet=\".*\"/localnet=\"{}\"/'.format(NEW_NETWORK+'\/24'), '/home/scripts/docs/firewall'))
    subprocess.run(('sed', '-i', 's/ifaceIn=\".*\"/ifaceIn=\"{}\"/'.format(NEW_INTERFACE_INTERNA), '/home/scripts/docs/firewall'))
    subprocess.run(('sed', '-i', 's/ifaceEx=\".*\"/ifaceEx=\"{}\"/'.format(NEW_INTERFACE_EXTERNA), '/home/scripts/docs/firewall'))
    # squid.conf
    subprocess.run(('sed', '-i', 's/acl sarg dst .*/acl sarg dst {}/'.format(IP_FIREWALL), '/home/scripts/docs/squid.conf'))
    subprocess.run(('sed', '-i', 's/acl localnet src .*/acl localnet src {}/'.format(NEW_NETWORK+'\/24'), '/home/scripts/docs/squid.conf'))
    subprocess.run(('sed', '-i', 's/http_port .*:3128/http_port {}:3128/'.format(IP_FIREWALL), '/home/scripts/docs/squid.conf'))


if __name__ == "__main__":
    general_change()
    firewall_change()
    ad_dhcp_change()
    files_change()
    
    
    