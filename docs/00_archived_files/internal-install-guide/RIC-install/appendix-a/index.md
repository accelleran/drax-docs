## Appendix A: 4G dRAX Provisioner - Keys and Certificates Generation

In general, TLS certificates only allow you to connect to a server if the URL of the server matches one of the subjects in the certificate configuration.

This section assumes the usage of `openssl` to handle TLS security due to its flexibility, even if  it is both complex to use and easy to make mistakes.
Customers can choose to use different options to generate the keys and certificates as long as of course the final output matches the content of this section.

### Create the certificates

#### Create the server.key

First thing is to create a key (if it doesn't exist yet):

``` bash
openssl genrsa -out server.key 4096
```

This command will create a RSA based server key with a key length of 4096 bits.

#### Create a server certificate

First, create the `cert.conf`.
Create a file like the example below and save it as `cert.conf`:

```
[ req ]
default_bits        = 2048
default_keyfile     = server-key.pem
distinguished_name  = subject
req_extensions      = req_ext
x509_extensions     = req_ext
string_mask         = utf8only

[ subject ]
countryName         = Country Name (2 letter code)
countryName_default     = BE

stateOrProvinceName     = State or Province Name (full name)
stateOrProvinceName_default = Example state

localityName            = Locality Name (eg, city)
localityName_default        = Example city

organizationName         = Organization Name (eg, company)
organizationName_default    = Example company

commonName          = Common Name (e.g. server FQDN or YOUR name)
commonName_default      = Example Company

emailAddress            = Email Address
emailAddress_default        = test@example.com

[ req_ext ]

subjectKeyIdentifier        = hash
basicConstraints        = CA:FALSE
keyUsage            = digitalSignature, keyEncipherment
subjectAltName          = @alternate_names
nsComment           = "OpenSSL Generated Certificate"

[ alternate_names ]
DNS.1        = localhost
IP.1         = 10.0.0.1
IP.2         = 10.20.20.20
```

Fill in the details, like the country, company name, etc.

**IMPORTANT:** Edit the last line of the file.
`IP.2` should be equal to IP where the provisioner will be running.
This is the `$NODE_IP` from the planning phase.
The default is set to 10.20.20.20.

To create the server certificate, use the following command:

``` bash
openssl req -new -key server.key -config cert.conf -out server.csr -batch
```

Command explanation:

  - `openssl req -new`: create a new certificate
  - `-key server.key`: use server.key as the private half of the certificate
  - `-config cert.conf`: use the configuration as a template
  - `-out server.csr`: generate a csr
  - `-batch`: don't ask about the configuration on the terminal

#### Create a self-signed client certificate

To create the client certificate, use the following command:

``` bash
openssl req -newkey rsa:4096 -nodes -keyout client.key -sha384 -x509 -days 3650 -out client.crt -subj /C=XX/ST=YY/O=RootCA
```

This command will create a `client.key` and `client.crt` from scratch to use for TLS-based authentication, in details the options are:

  - `openssl req`: create a certificate
  - `-newkey rsa:4096`: create a new client key
  - `-nodes`: do not encrypt the newly create client key with a passphrase (other options are -aes)
  - `-keyout client.key`: write the key to client.key
  - `-x509`: sign this certificate immediately
  - `-sha384`: use sha384 for signing the certificate`
  - `-days 3650`: this certificate is valid for ten years
  - `-subj /C=XX/ST=YY/O=RootCA`: use some default configuration
  - `-out client.crt`: write the certificate to client.crt

#### Sign the server certificate using the root certificate authority key

The server certificate needs to be signed by Accelleran.
To do so, please contact the Accelleran Customers Support Team and send us the following files you created previously:

* server.csr
* cert.conf

You will receive from Accelleran the following files:

* signed server.crt
* ca.crt

#### Verify the certificates work

The following commands should be used and return both OK:

``` bash
openssl verify -CAfile client.crt client.crt
openssl verify -CAfile ca.crt server.crt
```
