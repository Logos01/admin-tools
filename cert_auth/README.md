 Written 2015-10-02 by Logos < Logos01 @ irc.freenode.net >

 Certificate Authority configuration and generation script.
 Based on https://jamielinux.com/docs/openssl-certificate-authority

Locate and De-Tokenize all tokenized values before using.

    find . -type f -exec grep -H '<<.*>>' \;
    
    NOTE: DO NOT DE-TOKENIZE ANY INSTANCE OF "<<COMMONNAME>>".
    NOTE: The "<<.*>>"'s in the Usage statement of generate_server_cert can be ignored.
 

 Requires a functional Root and Intermediate CA Certificate

 With co-distributed files, execute the following commands to achieve this.
 

    basedir="/var/cert_auth"
    mkdir -p ${basedir}
    rsync -rv <<ADMIN-TOOLS/cert_auth>>/. ${basedir}
    
    cd ${basedir}
    bash ./generate_root_certificate
    
 To actually generate signed certificates (and associated configs, CSR, and private keys), see:
     /var/cert_auth/generate_server_cert -h
 For further information.
 Server certificates will be located in:
     /var/cert_auth/intermediate/certs/
 Server private keys will be located in:
     /var/cert_auth/intermediate/private/
 Server CSR (Certificate Signing Request) files will be located in:
     /var/cert_auth/intermediate/csrs/
 Server CSR-generating configs will be located in:
     /var/cert_auth/intermediate/confs/
     
All generated files will follow the naming convention:
    <<COMMONNAME>>.<<DOMAIN.TLD>>.<<TYPE>> (where TYPE could be "openssl.cnf" or "cert.pem" or "key.pem" or "csr.pem")
