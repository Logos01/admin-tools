 Written 2015-10-02 by Logos < Logos01 @ irc.freenode.net >

 Certificate Authority configuration and generation script.
 Based on https://jamielinux.com/docs/openssl-certificate-authority

 

 Requires a functional Root and Intermediate CA Certificate

 With co-distributed files, execute the following commands to achieve this.

    basedir="/var/cert_auth"
    mkdir -p ${basedir}
    rsync -rv <<ADMIN-TOOLS/cert_auth>>/. /var/cert_auth/

    cd ${basedir}

    openssl genrsa \
        -aes256 \
        -passin pass:${password} \
        -out private/ca.key.pem 4096

    chmod 0400 private/ca.key.pem
    
    openssl req -config openssl.cnf \
        -key private/ca.key.pem \
        -new \
        -x509 \
        -days 7300 \
        -sha256 \
        -extensions v3_ca \
        -out certs/ca.cert.pem \
        -passin pass:${password}

    <<FILL_IN_PROMPTS>>

    chmod 0444 certs/ca.cert.pem

    openssl genrsa \
        -aes256 \
        -passin pass:${password} \
        -out intermediate/private/intermediate.key.pem 4096

    chmod 0400 intermediate/private/intermediate.key.pem

    openssl req -config intermediate/openssl.cnf \
        -new \
        -sha256 \
        -passin pass:${password} \
        -key intermediate/private/intermediate.key.pem \
        -out intermediate/csr/intermediate.csr.pem

    <<FILL_IN_PROMPTS>>

    openssl ca -config ${basedir}/openssl.cnf \
        -extensions v3_intermediate_ca \
        -days 3650 \
        -notext \
        -md sha256 \
        -passin pass:${password}
        -in intermediate/csr/intermediate.csr.pem \
        -out intermediate/certs/intermediate.cert.pem \
        -batch

     chmod 0444 intermediate/certs/intermediate.cert.pem

     cat intermediate/certs/intermediate.cert.pem \
         certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem

     chmod 0444 intermediate/certs/ca-chain.cert.pem
