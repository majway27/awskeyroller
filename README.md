README.md

Purpose: Roll Individual Account key that is older than 60 days.

Dependencies:
sudo gem install aws-sdk parseconfig
fileutils and date should be recent ruby installs.

An AWS client creds file:
~/.aws/credentials
[default]
aws_access_key_id = AKI....
aws_secret_access_key = .....

[dev]
aws_access_key_id = AKI....
aws_secret_access_key = .....

[prod]
aws_access_key_id = AKI....
aws_secret_access_key = .....

Point at your creds file:
AWS_CONFIG_FILE = "/home/ubuntu/.aws/credentials"

All set!  Run as shell script.

Todo:
- Externalize config?
- Exception handling