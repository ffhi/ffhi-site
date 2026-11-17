packages {'iwinfo'}

features {
	'authorized-keys', -- schreibt authorized_keys aus site.conf nach /etc/dropbear (Root-Login per Schlüssel)
	'autoupdater',
	'ebtables-filter-multicast',
	'config-mode-domain-select',
	'config-mode-geo-location-osm',
	'ebtables-filter-ra-dhcp',
	'ebtables-limit-arp',
	'mesh-batman-adv-15',
	'mesh-vpn-wireguard',
	'respondd',
	'status-page',
	'web-advanced',
	'web-wizard',

}

if not device_class('tiny') then
	features {
		'wireless-encryption-wpa3'
	}
end
