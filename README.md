# AWS Load Balancer Security Group IP Management Script

This script allows you to easily add or remove IP addresses from the security groups of one or more AWS application load balancers.

## Requirements

- AWS CLI must be installed and configured with the appropriate credentials.
- `curl` must be installed.

## Usage

./albsg.sh [options]


### Options

- `-h`, `--help`: Show the help message and exit.
- `-r`, `--region REGION`: The AWS region to use.
- `-n`, `--name LOAD_BALANCER`: The name of a load balancer to add or remove your IP from (can be specified multiple times).
- `-p`, `--protocol PROTOCOL`: The protocol to allow or revoke (can be specified multiple times).
- `-P`, `--port PORT`: The port to allow or revoke (can be specified multiple times).
- `-a`, `--add`: Add your IP to the selected load balancers.
- `-d`, `--remove`: Remove your IP from the selected load balancers.
- `-A`, `--all`: Add or remove your IP from all available load balancers.
- `-l`, `--list`: List available load balancers in the specified region.
- `-i`, `--ip IP`: An additional IP address to add or remove (can be specified multiple times) Note: if used it overrides your IP so you need to specify your IP in -i.

### Examples

List available load balancers in the `us-east-1` region:

`./albsg.sh --region us-east-1 --list`


Add your public IP address to the security group of a load balancer named `my-load-balancer` in the `us-east-1` region, allowing access over HTTP and HTTPS:

`./albsg.sh --region us-east-1 --name my-load-balancer --protocol tcp --port 80 --protocol tcp --port 443 --add`


Remove your public IP address from the security group of a load balancer named `my-load-balancer` in the `us-east-1` region, revoking access over HTTP and HTTPS:

`./albsg.sh --region us-east-1 --name my-load-balancer --protocol tcp --port 80 --protocol tcp --port 443 --remove`


Add the IP addresses `203.0.113.0` and `203.0.113.1` to the security group of a load balancer named `my-load-balancer` in the `us-east-1` region, allowing access over HTTP and HTTPS:

`./albsg.sh --region us-east-1 --name my-load-balancer --protocol tcp --port 80 --protocol tcp --port 443 --add --ip 203.0.113.0 --ip 203.0.113.1`


Remove the IP addresses `203.0.113.0` and `203.0.113.1` from the security group of a load balancer named `my-load-balancer` in the `us-east-1` region, revoking access over HTTP and HTTPS:

`./albsg.sh --region us-east-1 --name my-load-balancer --protocol tcp --port 80 --protocol tcp --port 443 --remove --ip 203.0.113.0 --ip 203.0.113.1`



## Conclusion

This script provides a convenient way to manage the IP addresses allowed to access your AWS application load balancers. With its various options, you can easily add or remove your own IP address or additional IP addresses from one or more load balancers in a specified region. You can also list available load balancers in a region and specify the protocols and ports to allow or revoke. This script is a useful tool for managing access to your AWS application load balancers.