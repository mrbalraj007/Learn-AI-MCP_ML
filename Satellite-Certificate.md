# Configure Red Hat Satellite with a Custom SSL Certificate

This article outlines a practical and reliable way to replace the default SSL certificate on a Red Hat Satellite server and its Capsule server with a custom certificate. The steps below are written in a simple, business-friendly style so they can be shared in a team knowledge base or Confluence page without losing technical detail.

## Purpose

Using a trusted certificate helps ensure that:

- Satellite traffic is encrypted and secure
- clients trust the server endpoint
- browser or host warnings are reduced
- the environment looks more professional and controlled

## Technologies used

This setup relies on a combination of well-known enterprise tools and services:

- Red Hat Satellite
- Red Hat Capsule Server
- OpenSSL for certificate generation
- Katello and Foreman components
- RHSM, DNF, and RPM for client registration and package handling
- SSH for secure file transfer between servers

## Before you begin

Make sure the following items are ready:

- Root or sudo access on the Satellite and Capsule hosts
- A valid X.509 certificate, private key, and CA bundle
- A fully qualified domain name that matches the certificate subject and SAN entries
- DNS resolution for the Satellite and Capsule hosts
- A working backup of the existing certificates, if available

## Step 1: Review the current certificate state

Start by checking the current host details and the existing Satellite certificate setup.

```bash
hostname -f
hammer ping
```

If you want to inspect the current certificate on the Satellite server, use:

```bash
openssl x509 -in /etc/pki/katello/certs/katello-apache.crt -text | egrep '(Issuer: |Subject: | CA: | DNS: | Digital |Not Before|Not After)'
```

This gives a quick view of the issuer, subject, validity period, and subject alternative name values.

## Step 2: Prepare the certificate files

Create a working directory for the new certificate materials.

```bash
mkdir -p /root/satellite_cert
mkdir -p /root/capsule_cert
```

Use a private key that is unencrypted and free of a passphrase. In many environments, this is the safest and easiest approach for automated service use.

```bash
openssl genrsa -out /root/satellite_cert/satellite_cert_key.pem 4096
```

A sample OpenSSL configuration file can be created as follows:

### For Satellite Server
```ini
# /root/satellite_cert
# [root@xxxxdc2sat02 satellite_cert]# cat openssl.cnf
[ req ]
req_extensions = v3_req
distinguished_name = req_distinguished_name
x509_extensions = usr_cert
prompt = no

[ req_distinguished_name ]
C  = AU
ST = VIC
L  = xxxx
O  = Jetstar Airways Pty Ltd
OU = IT
CN = xxxxdc2sat02singhworld.org

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth, codeSigning, emailProtection
subjectAltName = @alt_names

[ usr_cert ]
basicConstraints = CA:FALSE
nsCertType = client, server, email
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth, codeSigning, emailProtection
nsComment = "OpenSSL Generated Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer

[ alt_names ]
DNS.1 = xxxxdc2sat02.singhworld.org
DNS.2 = xxxxdc2sat02
IP.1  = 172.23.6.105
```
Save this as a file such as **/root/satellite_cert/openssl.cnf**.

### For Capsule Server
```ini
# cd /root/capsule_cert
# [root@xxxxdc2sat02 capsule_cert]# pwd
#[root@xxxxdc2sat02 capsule_cert]# cat openssl.cnf
[ req ]
req_extensions = v3_req
distinguished_name = req_distinguished_name
x509_extensions = usr_cert
prompt = no

[ req_distinguished_name ]
C  = AU
ST = VIC
L  = xxxx
O  = Jetstar Airways Pty Ltd
OU = IT
CN = xxxxdc2cap02.singhworld.org

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth, codeSigning, emailProtection
subjectAltName = @alt_names

[ usr_cert ]
basicConstraints = CA:FALSE
nsCertType = client, server, email
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth, codeSigning, emailProtection
nsComment = "OpenSSL Generated Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer

[ alt_names ]
DNS.1 = xxxxdc2cap02.singhworld.org
DNS.2 = xxxxdc2cap02
IP.1  = 172.23.36.212
```

Save this as a file such as **/root/capsule_cert/openssl.cnf**.

## Step 3: Generate a CSR

Generate the certificate signing request from the key and the configuration file.

```bash
openssl req -new -key /root/satellite_cert/satellite_cert_key.pem -config /root/satellite_cert/openssl.cnf -out /root/satellite_cert/satellite_cert_csr.pem
```

Review the CSR to confirm that the subject and SAN details are correct.

```bash
openssl req -in /root/satellite_cert/satellite_cert_csr.pem -noout -text | grep -A5 "Subject Alternative Name"
```

## Step 4: Validate the certificate before installation

Before applying the certificate, validate the files that will be used.

```bash
katello-certs-check -c /root/satellite_cert/satellite_cert.pem -k /root/satellite_cert/satellite_cert_key.pem -b /root/satellite_cert/ca_cert_bundle.pem
```

If the validation passes, the certificate structure and chain are in good shape and ready for Satellite use.

## Step 5: Apply the certificate to the Satellite server

Update the Red Hat Satellite installation with the custom certificate details.

```bash
satellite-installer --scenario satellite \
  --certs-server-cert "/root/satellite_cert/satellite_cert.pem" \
  --certs-server-key "/root/satellite_cert/satellite_cert_key.pem" \
  --certs-server-ca-cert "/root/satellite_cert/ca_cert_bundle.pem" \
  --certs-update-server --certs-update-server-ca
```

This step updates the server certificate and the relevant Katello and Foreman services.

## Step 6: Verify the new certificate on Satellite

After the installer completes, verify that the new certificate is now in place.

```bash
openssl x509 -in /etc/pki/katello/certs/katello-apache.crt -text | egrep '(Issuer: |Subject: | CA: | DNS: | Digital |Not Before|Not After)'
```

```bash
openssl x509 -in /etc/foreman-proxy/ssl_cert.pem -text | egrep '(Issuer: |Subject: | CA: | DNS: | Digital |Not Before|Not After)'
```

These checks confirm that the live certificate files reflect the new values.

## Step 7: Register a client to the Satellite server

To confirm the environment is working end to end, register a client host against the Satellite server.

```bash
openssl s_client -connect xxxxdc2sat02.singhworld.org:443 -showcerts
openssl s_client -connect xxxxdc2sat02.singhworld.org:443 -CApath /etc/rhsm/ca
```

Then install the CA package and register the host.

```bash
curl -k -O https://xxxxdc2sat02.singhworld.org/pub/katello-ca-consumer-latest.noarch.rpm
rpm -Uvh katello-ca-consumer-latest.noarch.rpm
ls -l /etc/rhsm/ca/
rpm -ql $(rpm -qa | grep katello-ca)
```

This confirms that the client can trust the Satellite endpoint and receive the correct CA chain.

## Step 8: Prepare the Capsule server certificate

The same approach is used for the Capsule server. Create a separate working folder and generate a new certificate for the Capsule host.

```bash
mkdir -p /root/capsule_cert
openssl genrsa -out /root/capsule_cert/capsule_cert_key.pem 4096
```

Generate the CSR for the Capsule FQDN.

```bash
openssl req -new -key /root/capsule_cert/capsule_cert_key.pem -config /root/capsule_cert/openssl.cnf -out /root/capsule_cert/capsule_cert_csr.pem
```

Validate the certificate before applying it.

```bash
openssl x509 -in /root/capsule_cert/capsule_cert.pem -text -noout
```

```bash
katello-certs-check -t capsule -c /root/capsule_cert/capsule_cert.pem -k /root/capsule_cert/capsule_cert_key.pem -b /root/capsule_cert/ca_cert_bundle.pem
```

## Step 9: Generate the Capsule certificate bundle on Satellite

Run the certificate generation process from the **Satellite server**.

Will create a alise for capsule as below
```bash
CAPSULE=xxxxdc2cap02.singhworld.org
```
Run the below command
```bash
capsule-certs-generate --foreman-proxy-fqdn "$CAPSULE" \
  --certs-tar "~/$CAPSULE-certs.tar" \
  --server-cert "/root/capsule_cert/capsule_cert.pem" \
  --server-key "/root/capsule_cert/capsule_cert_key.pem" \
  --server-ca-cert "/root/capsule_cert/ca_cert_bundle.pem" \
  --certs-update-server
```

Copy the generated archive to the Capsule host.

```bash
 #Copy the following file /root/xxxxdc2cap02.singhworld.org-certs.tar to the system xxxxdc2cap02.singhworld.org at the following location /root/xxxxdc2cap02.singhworld.org-certs.tar
scp /root/xxxxdc2cap02.singhworld.org-certs.tar root@xxxxdc2cap02.singhworld.org:/root/xxxxdc2cap02.singhworld.org-certs.tar
```
**Note:** # it will generate the following command, which needs to be run on capsule server.

```ini
satellite-installer\
                    --scenario capsule\
                    --certs-tar-file                              "/root/xxxxdc2cap02.singhworld.org-certs.tar"\
                    --foreman-proxy-foreman-base-url              "https://xxxxdc2sat02.singhworld.org"\
                    --foreman-proxy-trusted-hosts                 "xxxxdc2sat02.singhworld.org"\
                    --foreman-proxy-trusted-hosts                 "xxxxdc2cap02.singhworld.org"\
                    --foreman-proxy-oauth-consumer-key            "36H9piVNFGKK82XzsPKbNK3iNNKSiX8o"\
                    --foreman-proxy-oauth-consumer-secret         "LTrfi3hRVWof8uWQHe3DrnQ8CNst7xVF"
```

## Step 10: Install the Capsule certificate on the Capsule host

On the **Capsule server**, run the installer using the archive that was copied over.

```bash
satellite-installer\
                    --scenario capsule\
                    --certs-tar-file                              "/root/xxxxdc2cap02.singhworld.org-certs.tar"\
                    --foreman-proxy-foreman-base-url              "https://xxxxdc2sat02.singhworld.org"\
                    --foreman-proxy-trusted-hosts                 "xxxxdc2sat02.singhworld.org"\
                    --foreman-proxy-trusted-hosts                 "xxxxdc2cap02.singhworld.org"\
                    --foreman-proxy-oauth-consumer-key            "36H9piVNFGKK82XzsPKbNK3iNNKSiX8o"\
                    --foreman-proxy-oauth-consumer-secret         "LTrfi3hRVWof8uWQHe3DrnQ8CNst7xVF"

```

If your environment uses explicit OAuth consumer values, replace the placeholder values below with the ones assigned to your deployment.

```bash
satellite-installer \
  --scenario capsule \
  --certs-tar-file "/root/$CAPSULE-certs.tar" \
  --foreman-proxy-foreman-base-url "https://xxxxdc2sat02.singhworld.org" \
  --foreman-proxy-trusted-hosts "xxxxdc2sat02.singhworld.org" \
  --foreman-proxy-trusted-hosts "$CAPSULE" \
  --foreman-proxy-oauth-consumer-key "<consumer-key>" \
  --foreman-proxy-oauth-consumer-secret "<consumer-secret>"
```

## Step 11: Verify the Capsule endpoint

Check that the Capsule server is presenting the new certificate.

```bash
openssl s_client -connect xxxxdc2cap02.singhworld.org:443 -showcerts
openssl s_client -connect xxxxdc2cap02.singhworld.org:443 -CApath /etc/rhsm/ca
```

For client hosts, the same CA package process can be used against the Capsule server.

```bash
rpm -qa | grep katello-ca
curl -k -O https://xxxxdc2cap02.singhworld.org/pub/katello-ca-consumer-latest.noarch.rpm
rpm -Uvh katello-ca-consumer-latest.noarch.rpm
ls -l /etc/rhsm/ca/
rpm -ql $(rpm -qa | grep katello-ca)
```

## Troubleshooting tips

If the certificate does not work as expected, check the following:

- The certificate common name and SAN values match the host FQDN exactly
- The CA bundle includes the full trust chain
- The Satellite and Capsule services were restarted successfully after the change
- Firewall rules and ports allow HTTPS traffic
- Clients have the updated CA package installed

## Final note

This process is a standard way to move a Red Hat Satellite environment from default certificate handling to a more controlled and trusted certificate model. In most cases, the work is straightforward when the certificate files, hostnames, and CA chain are prepared correctly.
