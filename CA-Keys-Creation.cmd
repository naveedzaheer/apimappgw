:: Create root certs
:: Please use your own custom domain name as nzazuredemo.com is only used as a reference
openssl genrsa -des3 -out nzazuredemo.key 4096

openssl req -x509 -new -nodes -key nzazuredemo.key -sha256 -days 1825 -out nzazuredemo.pem

:: Create certs for APIM proxy, portal and management
openssl genrsa -out api.nzazuredemo.com.key 2048

:: make sure to private custom domain name such as api.nzazuredemo.com, for CN name
openssl req -new -key api.nzazuredemo.com.key -out api.nzazuredemo.com.csr

openssl x509 -req -in api.nzazuredemo.com.csr -CA nzazuredemo.pem -CAkey nzazuredemo.key -CAcreateserial -out api.nzazuredemo.com.crt -days 1825 -sha256

openssl pkcs12 -export -out api.nzazuredemo.com.pfx -inkey api.nzazuredemo.com.key -in api.nzazuredemo.com.crt

:: make sure to private custom domain name such as portal.nzazuredemo.com, for CN name
openssl genrsa -out portal.nzazuredemo.com.key 2048

openssl req -new -key portal.nzazuredemo.com.key -out portal.nzazuredemo.com.csr

openssl x509 -req -in portal.nzazuredemo.com.csr -CA nzazuredemo.pem -CAkey nzazuredemo.key -CAcreateserial -out portal.nzazuredemo.com.crt -days 1825 -sha256

openssl pkcs12 -export -out portal.nzazuredemo.com.pfx -inkey portal.nzazuredemo.com.key -in portal.nzazuredemo.com.crt

:: make sure to private custom domain name such as management.nzazuredemo.com, for CN name
openssl genrsa -out management.nzazuredemo.com.key 2048

openssl req -new -key management.nzazuredemo.com.key -out management.nzazuredemo.com.csr

openssl x509 -req -in management.nzazuredemo.com.csr -CA nzazuredemo.pem -CAkey nzazuredemo.key -CAcreateserial -out management.nzazuredemo.com.crt -days 1825 -sha256

openssl pkcs12 -export -out management.nzazuredemo.com.pfx -inkey management.nzazuredemo.com.key -in management.nzazuredemo.com.crt
