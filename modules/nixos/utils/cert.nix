{ config, ... }:

{
  environment.etc."ssl/cert.pem".source = config.security.pki.caBundle;
}
