#!/bin/bash
# Laravel Installer
# Script by Juan
# 
# Illegal selling and redistribution of this script is strictly prohibited
# Please respect author's Property
# Binigay sainyo ng libre, ipamahagi nyo rin ng libre.
#
#

 # Now check if our machine is in root user, if not, this script exits
 # If you're on sudo user, run `sudo su -` first before running this script
if [[ $EUID -ne 0 ]];then
 ScriptMessage
 echo -e "[\e[1;31mError\e[0m] This script must be run as root, exiting..."
 exit 1
fi

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors

Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan


function ip_address() {
  local IP="$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )"
  [ -z "${IP}" ] && IP="$( wget -qO- -t1 -T2 ipv4.icanhazip.com )"
  [ -z "${IP}" ] && IP="$( wget -qO- -t1 -T2 ipinfo.io/ip )"
  [ ! -z "${IP}" ] && echo "${IP}" || echo
} 
IPADDR="$(ip_address)"

function Updating() {
export DEBIAN_FRONTEND=noninteractive
sudo apt update
apt upgrade -y
}

function Installing() {
sudo apt install openssh-server
apt-get install zip ca-certificates nginx ruby apt-transport-https lsb-release curl gnupg2 software-properties-common -y
apt-get autoremove -y

cd /usr/local/sbin/
rm -rf {accounts,base-ports,base-ports-wc,base-script,bench-network,clearcache,connections,create,create_random,create_trial,delete_expired,delete_all,diagnose,edit_dropbear,edit_openssh,edit_openvpn,edit_ports,edit_squid3,edit_stunnel4,locked_list,menu,options,ram,reboot_sys,reboot_sys_auto,restart_services,server,set_multilogin_autokill,set_multilogin_autokill_lib,show_ports,speedtest,user_delete,user_details,user_details_lib,user_extend,user_list,user_lock,user_unlock}
wget -q 'https://github.com/yakult13/parte/raw/main/fixed1.zip'
unzip -qq fixed1.zip
rm -f fixed1.zip
chmod +x ./*
dos2unix ./* &> /dev/null
cd
}

function MOD() {

     # Removing some duplicated sshd server configs
 rm -f /etc/ssh/sshd_config*

 # Creating a SSH server config using cat eof tricks
 cat <<'MySSHConfig' > /etc/ssh/sshd_config
Port 22
PermitRootLogin yes
PubkeyAuthentication no
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp  /usr/lib/openssh/sftp-server
ClientAliveInterval 120
MySSHConfig

systemctl restart ssh

}

function service() {

# cREATING PROXY
cat <<'PROXY' > /usr/sbin/yakult
#!/usr/bin/python
import socket, threading, thread, select, signal, sys, time, getopt

# Listen
LISTENING_ADDR = '0.0.0.0'
if sys.argv[1:]:
  LISTENING_PORT = sys.argv[1]
else:
  LISTENING_PORT = 80

# Pass
PASS = ''

# CONST
BUFLEN = 4096 * 4
TIMEOUT = 3600
DEFAULT_HOST = '127.0.0.1:112'
RESPONSE = 'HTTP/1.1 101 <font color="red">GVPNHUB.COM</font>\r\n\r\nContent-Length: 104857600000\r\n\r\n'

class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
        self.threadsLock = threading.Lock()
        self.logLock = threading.Lock()

    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        intport = int(self.port)
        self.soc.bind((self.host, intport))
        self.soc.listen(0)
        self.running = True

        try:
            while self.running:
                try:
                    c, addr = self.soc.accept()
                    c.setblocking(1)
                except socket.timeout:
                    continue

                conn = ConnectionHandler(c, self, addr)
                conn.start()
                self.addConn(conn)
        finally:
            self.running = False
            self.soc.close()

    def printLog(self, log):
        self.logLock.acquire()
        print log
        self.logLock.release()

    def addConn(self, conn):
        try:
            self.threadsLock.acquire()
            if self.running:
                self.threads.append(conn)
        finally:
            self.threadsLock.release()

    def removeConn(self, conn):
        try:
            self.threadsLock.acquire()
            self.threads.remove(conn)
        finally:
            self.threadsLock.release()

    def close(self):
        try:
            self.running = False
            self.threadsLock.acquire()

            threads = list(self.threads)
            for c in threads:
                c.close()
        finally:
            self.threadsLock.release()


class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.clientClosed = False
        self.targetClosed = True
        self.client = socClient
        self.client_buffer = ''
        self.server = server
        self.log = 'Connection: ' + str(addr)

    def close(self):
        try:
            if not self.clientClosed:
                self.client.shutdown(socket.SHUT_RDWR)
                self.client.close()
        except:
            pass
        finally:
            self.clientClosed = True

        try:
            if not self.targetClosed:
                self.target.shutdown(socket.SHUT_RDWR)
                self.target.close()
        except:
            pass
        finally:
            self.targetClosed = True

    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)

            hostPort = self.findHeader(self.client_buffer, 'X-Real-Host')

            if hostPort == '':
                hostPort = DEFAULT_HOST

            split = self.findHeader(self.client_buffer, 'X-Split')

            if split != '':
                self.client.recv(BUFLEN)

            if hostPort != '':
                passwd = self.findHeader(self.client_buffer, 'X-Pass')
				
                if len(PASS) != 0 and passwd == PASS:
                    self.method_CONNECT(hostPort)
                elif len(PASS) != 0 and passwd != PASS:
                    self.client.send('HTTP/1.1 400 WrongPass!\r\n\r\n')
                elif hostPort.startswith('127.0.0.1') or hostPort.startswith('localhost'):
                    self.method_CONNECT(hostPort)
                else:
                    self.client.send('HTTP/1.1 403 Forbidden!\r\n\r\n')
            else:
                print '- No X-Real-Host!'
                self.client.send('HTTP/1.1 400 NoXRealHost!\r\n\r\n')

        except Exception as e:
            self.log += ' - error: ' + e.strerror
            self.server.printLog(self.log)
	    pass
        finally:
            self.close()
            self.server.removeConn(self)

    def findHeader(self, head, header):
        aux = head.find(header + ': ')

        if aux == -1:
            return ''

        aux = head.find(':', aux)
        head = head[aux+2:]
        aux = head.find('\r\n')

        if aux == -1:
            return ''

        return head[:aux];

    def connect_target(self, host):
        i = host.find(':')
        if i != -1:
            port = int(host[i+1:])
            host = host[:i]
        else:
            if self.method=='CONNECT':
                port = 443
            else:
                port = sys.argv[1]

        (soc_family, soc_type, proto, _, address) = socket.getaddrinfo(host, port)[0]

        self.target = socket.socket(soc_family, soc_type, proto)
        self.targetClosed = False
        self.target.connect(address)

    def method_CONNECT(self, path):
        self.log += ' - CONNECT ' + path

        self.connect_target(path)
        self.client.sendall(RESPONSE)
        self.client_buffer = ''

        self.server.printLog(self.log)
        self.doCONNECT()

    def doCONNECT(self):
        socs = [self.client, self.target]
        count = 0
        error = False
        while True:
            count += 1
            (recv, _, err) = select.select(socs, [], socs, 3)
            if err:
                error = True
            if recv:
                for in_ in recv:
		    try:
                        data = in_.recv(BUFLEN)
                        if data:
			    if in_ is self.target:
				self.client.send(data)
                            else:
                                while data:
                                    byte = self.target.send(data)
                                    data = data[byte:]

                            count = 0
			else:
			    break
		    except:
                        error = True
                        break
            if count == TIMEOUT:
                error = True
            if error:
                break


def print_usage():
    print 'Usage: proxy.py -p <port>'
    print '       proxy.py -b <bindAddr> -p <port>'
    print '       proxy.py -b 0.0.0.0 -p 80'

def parse_args(argv):
    global LISTENING_ADDR
    global LISTENING_PORT
    
    try:
        opts, args = getopt.getopt(argv,"hb:p:",["bind=","port="])
    except getopt.GetoptError:
        print_usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print_usage()
            sys.exit()
        elif opt in ("-b", "--bind"):
            LISTENING_ADDR = arg
        elif opt in ("-p", "--port"):
            LISTENING_PORT = int(arg)


def main(host=LISTENING_ADDR, port=LISTENING_PORT):
    print "\n:-------PythonProxy-------:\n"
    print "Listening addr: " + LISTENING_ADDR
    print "Listening port: " + str(LISTENING_PORT) + "\n"
    print ":-------------------------:\n"
    server = Server(LISTENING_ADDR, LISTENING_PORT)
    server.start()
    while True:
        try:
            time.sleep(2)
        except KeyboardInterrupt:
            print 'Stopping...'
            server.close()
            break

#######    parse_args(sys.argv[1:])
if __name__ == '__main__':
    main()

PROXY

}

function service1() {

cat << END > /lib/systemd/system/yakult.service
[Unit]
Description=Yakult
Documentation=https://google.com
After=network.target nss-lookup.target
[Service]
Type=simple
User=root
NoNewPrivileges=true
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/bin/python -O /usr/sbin/yakult
ProtectSystem=true
ProtectHome=true
RemainAfterExit=yes
Restart=on-failure
[Install]
WantedBy=multi-user.target
END


systemctl daemon-reload
systemctl enable yakult
systemctl restart yakult

}
    
function InsOpenVPN() {
apt install openvpn -y
opam=`find /usr -name openvpn*auth-pam.so`

 # Checking if openvpn folder is accidentally deleted or purged
 if [[ ! -e /etc/openvpn ]]; then
  mkdir -p /etc/openvpn
 fi

 # Removing all existing openvpn server files
 rm -rf /etc/openvpn/*

 # Creating server.conf, ca.crt, server.crt and server.key
 cat <<'myOpenVPNconf1' > /etc/openvpn/server_tcp.conf
# GVPNHUB
port 1194
proto tcp
dev tun
topology subnet
server 10.10.0.0 255.255.0.0
ifconfig-pool-persist ipp.save
ca /etc/openvpn/ca.crt
dh /etc/openvpn/dh.pem
cert /etc/openvpn/xJuans.crt
key /etc/openvpn/xJuans.key
tls-cipher TLS-ECDHE-RSA-WITH-AES-128-GCM-SHA256
ncp-disable
username-as-common-name
verify-client-cert none
plugin $opam login
script-security 2
auth none
cipher none
push "verb 3"
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-renew"
push "block-outside-dns"
push "register-dns"
push "dhcp-option DNS 1.0.0.1"
push "dhcp-option DNS 1.0.0.1"
keepalive 5 60
tcp-nodelay
reneg-sec 0
persist-key
persist-tun
log-append log/openvpn.log
verb 3

myOpenVPNconf1

 
 cat <<'EOF7'> /etc/openvpn/ca.crt
-----BEGIN CERTIFICATE-----
MIIDxjCCA02gAwIBAgIUHOYpgZtNLLVaLXdqWXPl2wXN7zAwCgYIKoZIzj0EAwIw
gasxCzAJBgNVBAYTAlBIMREwDwYDVQQIDAhCYXRhbmdhczEWMBQGA1UEBwwNQmF0
YW5nYXMgQ2l0eTEXMBUGA1UECgwOR2FtZXJzIFZQTiBIdWIxGTAXBgNVBAsMEFBo
Q29ybmVyLUdWUE5IVUIxFzAVBgNVBAMMDkdWUE5IVUItU2VydmVyMSQwIgYJKoZI
hvcNAQkBFhVpbWFwc3ljaG8yOEBnbWFpbC5jb20wIBcNMjEwMTI4MTM0NTI3WhgP
MjA4MDAzMTkxMzQ1MjdaMIGrMQswCQYDVQQGEwJQSDERMA8GA1UECAwIQmF0YW5n
YXMxFjAUBgNVBAcMDUJhdGFuZ2FzIENpdHkxFzAVBgNVBAoMDkdhbWVycyBWUE4g
SHViMRkwFwYDVQQLDBBQaENvcm5lci1HVlBOSFVCMRcwFQYDVQQDDA5HVlBOSFVC
LVNlcnZlcjEkMCIGCSqGSIb3DQEJARYVaW1hcHN5Y2hvMjhAZ21haWwuY29tMHYw
EAYHKoZIzj0CAQYFK4EEACIDYgAEDY0BO/SRsYYGZy+PKyCf7jruD/Sanr2GrNxC
YQ8vzbUqKvyjP+wIQXBJ//Ba8bOJH3K2dtKh3hzbaDdxzSjCxG9W36YdBCXxbDl8
kWMNjugeNySZ4QgVm5mFEA4r4uEYo4IBLDCCASgwHQYDVR0OBBYEFOxhLQt+r3qA
q173jqObhxF3BnESMIHrBgNVHSMEgeMwgeCAFOxhLQt+r3qAq173jqObhxF3BnES
oYGxpIGuMIGrMQswCQYDVQQGEwJQSDERMA8GA1UECAwIQmF0YW5nYXMxFjAUBgNV
BAcMDUJhdGFuZ2FzIENpdHkxFzAVBgNVBAoMDkdhbWVycyBWUE4gSHViMRkwFwYD
VQQLDBBQaENvcm5lci1HVlBOSFVCMRcwFQYDVQQDDA5HVlBOSFVCLVNlcnZlcjEk
MCIGCSqGSIb3DQEJARYVaW1hcHN5Y2hvMjhAZ21haWwuY29tghQc5imBm00stVot
d2pZc+XbBc3vMDAMBgNVHRMEBTADAQH/MAsGA1UdDwQEAwIBBjAKBggqhkjOPQQD
AgNnADBkAjAlVh2EtpofZcHyTPD6u/GrKCPvSPqdz2+6/ybXuXa+VRGzoTrQ3cRf
VZPAbgSqEskCMHnvJ9Pm/bGbaXQ6pLgYeUBWRr1wWPeXFVs4caKRpSzZC73dKFdZ
Al+0Oxso76FBPg==
-----END CERTIFICATE-----
EOF7
 cat <<'EOF9'> /etc/openvpn/xJuans.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            74:6e:46:3f:6b:45:3e:d4:f2:38:ba:4f:fb:74:31:c8
        Signature Algorithm: ecdsa-with-SHA256
        Issuer: C=PH, ST=Batangas, L=Batangas City, O=Gamers VPN Hub, OU=PhCorner-GVPNHUB, CN=GVPNHUB-Server/emailAddress=imapsycho28@gmail.com
        Validity
            Not Before: Jan 28 13:49:05 2021 GMT
            Not After : Mar 19 13:49:05 2080 GMT
        Subject: C=PH, ST=Batangas, L=Batangas City, O=Gamers VPN Hub, OU=PhCorner-GVPNHUB, CN=GVPNHUB-Server/emailAddress=imapsycho28@gmail.com
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (384 bit)
                pub:
                    04:58:ef:b8:3d:fb:4b:59:26:c4:99:c4:9d:a9:c0:
                    d5:2a:a8:b2:85:8c:c3:8b:bf:c8:c7:05:1a:0b:bb:
                    75:df:91:38:03:6b:a7:be:b5:c4:b9:81:0a:8e:8f:
                    75:63:72:7e:3c:9e:37:12:d8:5c:25:af:0c:25:9c:
                    5d:85:ce:96:91:9f:be:6f:0b:a8:06:a9:ad:18:cf:
                    f9:76:8a:24:10:b4:89:b7:00:9d:72:f8:70:00:8f:
                    de:4b:2e:35:77:cb:b4
                ASN1 OID: secp384r1
                NIST CURVE: P-384
        X509v3 extensions:
            X509v3 Basic Constraints:
                CA:FALSE
            X509v3 Subject Key Identifier:
                03:62:1C:3D:ED:E9:5B:F2:A6:0F:41:37:AD:AE:BB:8A:86:2A:E1:12
            X509v3 Authority Key Identifier:
                keyid:EC:61:2D:0B:7E:AF:7A:80:AB:5E:F7:8E:A3:9B:87:11:77:06:71:12
                DirName:/C=PH/ST=Batangas/L=Batangas City/O=Gamers VPN Hub/OU=PhCorner-GVPNHUB/CN=GVPNHUB-Server/emailAddress=imapsycho28@gmail.com
                serial:1C:E6:29:81:9B:4D:2C:B5:5A:2D:77:6A:59:73:E5:DB:05:CD:EF:30

            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Key Usage:
                Digital Signature, Key Encipherment
            X509v3 Subject Alternative Name:
                DNS:GVPNHUB-Server
    Signature Algorithm: ecdsa-with-SHA256
         30:65:02:31:00:ea:63:07:9e:9f:ae:0a:bf:0e:c7:07:bc:e4:
         68:83:ea:5f:1a:af:11:f0:ef:47:a7:c7:42:eb:cd:d2:9e:76:
         00:9c:34:f7:aa:23:f9:2d:c3:39:a5:9a:19:a0:dc:32:f2:02:
         30:16:f9:d9:0d:46:e9:b4:f3:1a:18:e1:36:f3:e6:62:8c:2f:
         a5:77:30:30:6a:9c:4f:13:11:a9:69:68:21:8a:31:f1:dc:8a:
         56:44:81:c9:1e:f3:17:d2:e7:38:7c:c1:52
-----BEGIN CERTIFICATE-----
MIID8DCCA3agAwIBAgIQdG5GP2tFPtTyOLpP+3QxyDAKBggqhkjOPQQDAjCBqzEL
MAkGA1UEBhMCUEgxETAPBgNVBAgMCEJhdGFuZ2FzMRYwFAYDVQQHDA1CYXRhbmdh
cyBDaXR5MRcwFQYDVQQKDA5HYW1lcnMgVlBOIEh1YjEZMBcGA1UECwwQUGhDb3Ju
ZXItR1ZQTkhVQjEXMBUGA1UEAwwOR1ZQTkhVQi1TZXJ2ZXIxJDAiBgkqhkiG9w0B
CQEWFWltYXBzeWNobzI4QGdtYWlsLmNvbTAgFw0yMTAxMjgxMzQ5MDVaGA8yMDgw
MDMxOTEzNDkwNVowgasxCzAJBgNVBAYTAlBIMREwDwYDVQQIDAhCYXRhbmdhczEW
MBQGA1UEBwwNQmF0YW5nYXMgQ2l0eTEXMBUGA1UECgwOR2FtZXJzIFZQTiBIdWIx
GTAXBgNVBAsMEFBoQ29ybmVyLUdWUE5IVUIxFzAVBgNVBAMMDkdWUE5IVUItU2Vy
dmVyMSQwIgYJKoZIhvcNAQkBFhVpbWFwc3ljaG8yOEBnbWFpbC5jb20wdjAQBgcq
hkjOPQIBBgUrgQQAIgNiAARY77g9+0tZJsSZxJ2pwNUqqLKFjMOLv8jHBRoLu3Xf
kTgDa6e+tcS5gQqOj3Vjcn48njcS2FwlrwwlnF2FzpaRn75vC6gGqa0Yz/l2iiQQ
tIm3AJ1y+HAAj95LLjV3y7SjggFZMIIBVTAJBgNVHRMEAjAAMB0GA1UdDgQWBBQD
Yhw97elb8qYPQTetrruKhirhEjCB6wYDVR0jBIHjMIHggBTsYS0Lfq96gKte946j
m4cRdwZxEqGBsaSBrjCBqzELMAkGA1UEBhMCUEgxETAPBgNVBAgMCEJhdGFuZ2Fz
MRYwFAYDVQQHDA1CYXRhbmdhcyBDaXR5MRcwFQYDVQQKDA5HYW1lcnMgVlBOIEh1
YjEZMBcGA1UECwwQUGhDb3JuZXItR1ZQTkhVQjEXMBUGA1UEAwwOR1ZQTkhVQi1T
ZXJ2ZXIxJDAiBgkqhkiG9w0BCQEWFWltYXBzeWNobzI4QGdtYWlsLmNvbYIUHOYp
gZtNLLVaLXdqWXPl2wXN7zAwEwYDVR0lBAwwCgYIKwYBBQUHAwEwCwYDVR0PBAQD
AgWgMBkGA1UdEQQSMBCCDkdWUE5IVUItU2VydmVyMAoGCCqGSM49BAMCA2gAMGUC
MQDqYween64Kvw7HB7zkaIPqXxqvEfDvR6fHQuvN0p52AJw096oj+S3DOaWaGaDc
MvICMBb52Q1G6bTzGhjhNvPmYowvpXcwMGqcTxMRqWloIYox8dyKVkSByR7zF9Ln
OHzBUg==
-----END CERTIFICATE-----
EOF9
 cat <<'EOF10' > /etc/openvpn/xJuans.key
-----BEGIN PRIVATE KEY-----
MIG2AgEAMBAGByqGSM49AgEGBSuBBAAiBIGeMIGbAgEBBDCbbP09CnIUSkg7Y4qV
jl/Owf/AXFtDs+8E0moCX0L6lGREiHeGre9Wzziyg2qqS/ehZANiAARY77g9+0tZ
JsSZxJ2pwNUqqLKFjMOLv8jHBRoLu3XfkTgDa6e+tcS5gQqOj3Vjcn48njcS2Fwl
rwwlnF2FzpaRn75vC6gGqa0Yz/l2iiQQtIm3AJ1y+HAAj95LLjV3y7Q=
-----END PRIVATE KEY-----
EOF10
cat <<'EOF28' > /etc/openvpn/dh.pem
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEAlVC6TGc5lslb4j30NJ8VdH7iAmd3mM23FtYdgoz/wPzeWplDgnej
N39TK4pRfg2g3IdhtIdqgbgYFJveaxJhY1TOyaiwx5jHlq5mq2nPQtIQiOmk/LzZ
bxSuF+/kMDITbG04Ed6HQfTvUi2AAjM5w2S2CbiNB8fQp/ppCOekakkaHxxgLcc8
c0KP+6LkGAZM01IJIozNAqQ5k/uVC4MzkgE9EmSIz5a6p48k3WyJu2j8tBjQJuRb
z3pFYMzJx0RniuRVRRjIUF2hW6JLEQhqhTQZEDhnO7vW8rEcAfqwsaQ3sr8j7+FD
k/KPGLimSf3dMSKhb/T9JY7J96/lXiPUewIBAg==
-----END DH PARAMETERS-----
EOF28
cat <<'EOF29' > /etc/openvpn/ta.key
#
# 2048 bit OpenVPN static key
#
-----BEGIN OpenVPN Static key V1-----
7e15f11cddf9604647bc0fe181f174c1
3f6a9ecda3a4f0d759b4cf1bc4e092a4
fffe34d9c5d98eaab6e19572cc0c4153
753c9446209b737de772f938090705fd
5151e51ae95248b30723542fcf71d9c3
d60a12a1e35dcd73e2ac3acffaf33763
0753eede6eecee0536e7165ca4525ba2
c16e1fbc38b5bc2259f5200baab1b1bb
66e32855aab2d4a1d9e898adbc8486dc
64d87e3b1a164fc54f125a04fa572796
0f888b16d409cd3785bd8086153485eb
3af1dac1fe1f11170af786e56283f305
dfff819a87fefca63dd88cee89d39089
04c871b897fb30c2c405bf1fd6fcdfea
babf56ffea17c525a94e1c403b742c29
d43e69d056f19f5ed6b91c6696271a44
-----END OpenVPN Static key V1-----
EOF29
cat <<'EOF30' > /etc/openvpn/CLIENT.key
-----BEGIN PRIVATE KEY-----
MIG2AgEAMBAGByqGSM49AgEGBSuBBAAiBIGeMIGbAgEBBDD9JqzDjCtqrpDBtMM6
nkTbX+t8eq0U1qB5F3q6ykCm8E5gGrLLOQllP0nyFBZHGRyhZANiAASY+qLrArcf
EMIJ1Vc4RPrQS+XIirwXmB7Xj94ROlpHF38otKbYpJkKXXHdgIIKwYmmRK7MMNlt
4HWCg3YIzXdoC976X/5Y94sBii4b5lMm75btNVpOEEz5akG59J5j5hw=
-----END PRIVATE KEY-----
EOF30
cat <<'EOF31' > /etc/openvpn/CLIENT.crt
-----BEGIN CERTIFICATE-----
MIID1TCCA1ugAwIBAgIQP3A8M99pxRMyOIEH8ZoG/jAKBggqhkjOPQQDAjCBqzEL
MAkGA1UEBhMCUEgxETAPBgNVBAgMCEJhdGFuZ2FzMRYwFAYDVQQHDA1CYXRhbmdh
cyBDaXR5MRcwFQYDVQQKDA5HYW1lcnMgVlBOIEh1YjEZMBcGA1UECwwQUGhDb3Ju
ZXItR1ZQTkhVQjEXMBUGA1UEAwwOR1ZQTkhVQi1TZXJ2ZXIxJDAiBgkqhkiG9w0B
CQEWFWltYXBzeWNobzI4QGdtYWlsLmNvbTAgFw0yMTAxMjgxMzU5MTBaGA8yMDgw
MDMxOTEzNTkxMFowgasxCzAJBgNVBAYTAlBIMREwDwYDVQQIDAhCYXRhbmdhczEW
MBQGA1UEBwwNQmF0YW5nYXMgQ2l0eTEXMBUGA1UECgwOR2FtZXJzIFZQTiBIdWIx
GTAXBgNVBAsMEFBoQ29ybmVyLUdWUE5IVUIxFzAVBgNVBAMMDkdWUE5IVUItQ2xp
ZW50MSQwIgYJKoZIhvcNAQkBFhVpbWFwc3ljaG8yOEBnbWFpbC5jb20wdjAQBgcq
hkjOPQIBBgUrgQQAIgNiAASY+qLrArcfEMIJ1Vc4RPrQS+XIirwXmB7Xj94ROlpH
F38otKbYpJkKXXHdgIIKwYmmRK7MMNlt4HWCg3YIzXdoC976X/5Y94sBii4b5lMm
75btNVpOEEz5akG59J5j5hyjggE+MIIBOjAJBgNVHRMEAjAAMB0GA1UdDgQWBBQ7
k1OI68EH8CWjQ0EyeIVF7fewGDCB6wYDVR0jBIHjMIHggBTsYS0Lfq96gKte946j
m4cRdwZxEqGBsaSBrjCBqzELMAkGA1UEBhMCUEgxETAPBgNVBAgMCEJhdGFuZ2Fz
MRYwFAYDVQQHDA1CYXRhbmdhcyBDaXR5MRcwFQYDVQQKDA5HYW1lcnMgVlBOIEh1
YjEZMBcGA1UECwwQUGhDb3JuZXItR1ZQTkhVQjEXMBUGA1UEAwwOR1ZQTkhVQi1T
ZXJ2ZXIxJDAiBgkqhkiG9w0BCQEWFWltYXBzeWNobzI4QGdtYWlsLmNvbYIUHOYp
gZtNLLVaLXdqWXPl2wXN7zAwEwYDVR0lBAwwCgYIKwYBBQUHAwIwCwYDVR0PBAQD
AgeAMAoGCCqGSM49BAMCA2gAMGUCMQCcX8H4y/yh0FX+KfMlr0pddojAMgDxDzcL
5VfOMho4C3M391KsvzQX2NBkays6k+ICMEzaiI32hS2zvkspVCAsSANl/4nxKSdG
FPFq6nTFawZekRJycKDCTCXDXUaCpIXbAw==
-----END CERTIFICATE-----
EOF31

cat << 'iptabc' > /usr/sbin/iptab
#!/bin/bash
INET="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"
iptables -F
iptables -X
iptables -F -t nat
iptables -X -t nat
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -I POSTROUTING -o $INET -j MASQUERADE
iptables -A INPUT -j ACCEPT
iptables -A FORWARD -j ACCEPT
iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -m state --state ESTABLISHED --sport 22 -j ACCEPT
iptables -A INPUT -p udp -m state --state ESTABLISHED --sport 53 -j ACCEPT
iptables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED --dport 53 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED --dport 22 -j ACCEPT
iptables -t filter -A FORWARD -j REJECT --reject-with icmp-port-unreachable
iptabc

chmod +x /usr/sbin/iptab

 systemctl daemon-reload
 systemctl start openvpn@server_tcp
 systemctl enable openvpn@server_tcp
 systemctl restart openvpn@server_tcp

 
 # Creating nginx config for our ovpn config downloads webserver
 rm -rf /etc/nginx/sites-*

 cat <<'myNginxC' > /etc/nginx/conf.d/bonveio-ovpn-config.conf
# My OpenVPN Config Download Directory
server {
 listen 0.0.0.0:1998;
 server_name localhost;
 root /var/www/openvpn;
 index index.html;
}
myNginxC


cat << sysctl > /etc/sysctl.d/bbr.conf
net.ipv4.ip_forward=1
net.ipv4.tcp_rmem=65535 131072 4194304
net.ipv4.tcp_wmem=65535 131072 4194304
net.ipv4.ip_default_ttl=50
net.ipv4.tcp_congestion_control=bbr
net.core.wmem_default=262144
net.core.wmem_max=4194304
net.core.rmem_default=262144
net.core.rmem_max=4194304
net.core.netdev_budget=600
net.core.default_qdisc=fq
net.ipv6.conf.all.accept_ra=2
sysctl
sysctl --system

rm -rf /etc/nginx/sites-*
rm -rf /var/www/openvpn
mkdir -p /var/www/openvpn

cat <<wsovpn> /var/www/openvpn/wsovpn.ovpn
# CLICK 1 AD A DAY TO HELP US
# Ꮐᐯᑭᑎᕼᑌᗷ.com
client
dev tun
proto tcp
remote $IPADDR 112
remote-cert-tls server
tun-mtu 1500
mssfix 1450
auth-user-pass
auth sha256
cipher AES-256-CBC
comp-lzo
setenv CLIENT_CERT 1

<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/CLIENT.crt)
</cert>
<key>
$(cat /etc/openvpn/ta.key)
$(cat /etc/openvpn/CLIENT.key)
</key>
wsovpn

# Creating OVPN download site index.html
cat <<'mySiteOvpn' > /var/www/openvpn/index.html
<!DOCTYPE html>
<html lang="en">

<!-- GVPNHUB CONF SITE -->

<head>
<meta charset="utf-8" />
<title>GVPNHUB CONF SITE</title>
<meta name="description" content="This site is made only for GVPNHUB CONF's and are NOT FOR SALE" />
<meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" name="viewport" />
<meta name="theme-color" content="#000000" />
<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.8.2/css/all.css">
<link href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/mdbootstrap/4.8.3/css/mdb.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://www.w3schools.com/w3css/4/w3.css">
</head>
<body style="background-image: linear-gradient(to right, #6f9ee8, #427bd4, #195bc2)">
<div class="container justify-content-center>
    <div class="col-md">
        <div class="view" style="margin-top:3em;margin-bottom:3em;">
                <center>
                    <img class="w3-circle" src="https://github.com/imaPSYCHO/Parts/raw/main/jvpn.png" width="250px" height="250px" class="card-img-top">
                </center>
        </div>
    <div class="card">
        <div class="card-body">
            <h5 class="card-title"><center><b>Ꮐᐯᑭᑎᕼᑌᗷ.com CONF LIST</b></center></h5>
            <br>
            <ul class="list-group">
                <li class="list-group-item justify-content-between align-items-center" style="margin-bottom:1em;">
                    <p>Note
                        <span class="badge light-blue darken-4">Android/iOS/PC/Modem</span>
                        <br>
                        <small>WebsocketOVPN</small>
                    </p>
                    <a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/wsovpn.ovpn" style="float:right;"><i class="fa fa-download"></i> Download</a>
                </li>
       

            </ul>
        </div>
        </div>
    </div>
    <br>
    </div>
</body>
</html>
mySiteOvpn


 # Setting template's correct name,IP address and nginx Port
 sed -i "s|MyScriptName|$MyScriptName|g" /var/www/openvpn/index.html
 sed -i "s|NGINXPORT|$OvpnDownload_Port|g" /var/www/openvpn/index.html
 sed -i "s|IP-ADDRESS|$IPADDR|g" /var/www/openvpn/index.html

systemctl restart nginx
}

function ScriptMessage(){
 echo -e ""
 echo -e " \033[0;36m(｡◕‿◕｡)\033[0m \033[0;31mLaravel Installer \033[0m"
 echo -e " \033[0;31m Script Created:\033[0m \033[0;36mGVPNHUB-Juan\033[0m"
 echo -e ""

}

# Start of Installing Every Function
 
 ScriptMessage
 
 sleep 2

echo -e "\033[0;33m Updating... \033[0m"
Updating

echo -e "\033[0;33m Installing Updates...\033[0m"
Installing

echo -e "\033[0;33m Modifying System... \033[0m"
MOD

echo -e "\033[0;33m Getting Websocket Service... \033[0m"
service

echo -e "\033[0;33m Setting Up Websocket Service... \033[0m"
service1

echo -e "\033[0;33m Installing OpenVPN... \033[0m"
InsOpenVPN

clear 

# showing Additional Info
ScriptMessage

echo -e ""
echo -e "\033[0;33m Success Installation \033[0m"
echo -e ""
echo -e "\033[0;33m Script NOT FOR SALE \033[0m"
echo -e "\033[0;33m REPORT to kakatol@ninjadns.net \033[0m"

 # Clearing all logs from installation
 rm -rf /root/.bash_history && history -c && echo '' > /var/log/syslog

rm -rf /root/tes*

exit 1