#!/bin/bash

# ┌────────────────────────────────────────────────────────────────────┐
# │ Script Name: albsg.sh                                              │
# │ Description: This script let you manage ALBs security groups.      │
# │ Author: Omar XS                                                    │
# │ Date: 2023-06-24                                                   │
# └────────────────────────────────────────────────────────────────────┘


# Func: help
function display_help {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help                 Show this help message and exit"
    echo "  -r, --region REGION        The AWS region to use"
    echo "  -n, --name LOAD_BALANCER   The name of a load balancer to add or remove your IP from (can be specified multiple times)"
    echo "  -p, --protocol PROTOCOL    The protocol to allow or revoke (can be specified multiple times)"
    echo "  -P, --port PORT            The port to allow or revoke (can be specified multiple times)"
    echo "  -a, --add                  Add your IP to the selected load balancers"
    echo "  -d, --remove               Remove your IP from the selected load balancers"
    echo "  -A, --all                  Add or remove your IP from all available load balancers"
    echo "  -l, --list                 List available load balancers in the specified region"
    echo "  -i, --ip IP                An additional IP address to add or remove (can be specified multiple times) Note: if used it overrides your IP so you need to specify your IP in -i"
}

# Func: Check if exited with an error
function check_error {
    if [ $? -ne 0 ]
    then
        echo "An error occurred. Exiting."
        exit 1
    fi
}

# Parse args
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -h|--help)
        display_help
        exit 0
        ;;
        -r|--region)
        REGION="$2"
        shift # past argument
        shift # past value
        ;;
        -n|--name)
        LOAD_BALANCER_NAMES+=("$2")
        shift # past argument
        shift # past value
        ;;
        -p|--protocol)
        PROTOCOLS+=("$2")
        shift # past argument
        shift # past value
        ;;
        -P|--port)
        PORTS+=("$2")
        shift # past argument
        shift # past value
        ;;
        -a|--add)
        ACTION="add"
        shift # past argument
        ;;
        -d|--remove)
        ACTION="remove"
        shift # past argument
        ;;
        -A|--all)
        ALL="true"
        shift # past argument
        ;;
        -l|--list)
        LIST="true"
        shift # past argument
        ;;
         -i|--ip)
         IPS+=("$2")
         shift # past argument
         shift # past value
         ;;
         *)
         shift # unknown option
         ;;
     esac
done

# Options Checker here

if [ "$LIST" == "true" ] && [ "$REGION" == "" ]
then
    echo "Error: You must specify the --region option when using the --list option."
    exit 1
fi

if [ "$LIST" == "true" ] && ([ ${#LOAD_BALANCER_NAMES[@]} -ne 0 ] || [ ${#PROTOCOLS[@]} -ne 0 ] || [ ${#PORTS[@]} -ne 0 ] || [ "$ACTION" != "" ] || [ "$ALL" == "true" ])
then
    echo "Error: You cannot use any other options when using the --list option."
    exit 1
fi

if [ "$ACTION" == "" ] && [ "$LIST" != "true" ]
then
    echo "Error: You must specify either the --add or --remove option."
    exit 1
fi

if [ "$ACTION" == "add" ] && [ "$ACTION" == "remove" ]
then
    echo "Error: You cannot specify both the --add and --remove options."
    exit 1
fi

if [ ${#PROTOCOLS[@]} -ne ${#PORTS[@]} ]
then
    echo "Error: You must specify the same number of --protocol and --port options."
    exit 1
fi

if ([ ${#PROTOCOLS[@]} -eq 0 ] || [ ${#PORTS[@]} -eq 0 ]) && ([ "$ACTION" == "add" ] || [ "$ACTION" == "remove" ])
then
    echo "Error: You must specify at least one --protocol and one --port when using the --add or --remove option."
    exit 1
fi

if ([ ${#LOAD_BALANCER_NAMES[@]} -eq 0 ] && [ "$ALL" != "true" ]) && ([ "$ACTION" == "add" ] || [ "$ACTION" == "remove" ])
then
    echo "Error: You must specify at least one --name or the --all option when using the --add or --remove option."
    exit 1
fi

if [ ${#IPS[@]} -ne 0 ] && ([ "$REGION" == "" ] || [ "$ACTION" == "" ] || ([ ${#PROTOCOLS[@]} -eq 0 ] || [ ${#PORTS[@]} -eq 0 ]) || ([ ${#LOAD_BALANCER_NAMES[@]} -eq 0 ] && [ "$ALL" != "true" ]))
then
    echo "Error: You must specify the --region, --add or --remove, at least one --protocol and one --port, and at least one --name or the --all option when using the --ip option."
    exit 1
fi

if [ "$LIST" == "true" ]
then
    # List available LBs in region
    aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[*].LoadBalancerName' --output text | tr '\t' '\n'
else
    # Get the user's own IP
    USER_IP=$(curl -s http://checkip.amazonaws.com)
    check_error

    if [ "$ALL" == "true" ]
    then
        # Get ARNs
        LOAD_BALANCER_ARNS=$(aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[*].LoadBalancerArn' --output text)
        check_error

        if [ -z "$LOAD_BALANCER_ARNS" ]
        then
            echo "No load balancers found in the specified region."
            exit 0
        fi

        LOAD_BALANCER_ARNS=($LOAD_BALANCER_ARNS)
    else
        # Get ARNs
        LOAD_BALANCER_ARNS=()
        for LOAD_BALANCER_NAME in "${LOAD_BALANCER_NAMES[@]}"
        do
            LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers --names $LOAD_BALANCER_NAME --region $REGION --query 'LoadBalancers[*].LoadBalancerArn' --output text)
            check_error

            if [ -z "$LOAD_BALANCER_ARN" ]
            then
                echo "Load balancer not found: $LOAD_BALANCER_NAME"
                exit 1
            fi

            LOAD_BALANCER_ARNS+=("$LOAD_BALANCER_ARN")
        done
    fi

    for LOAD_BALANCER_ARN in "${LOAD_BALANCER_ARNS[@]}"
    do
      # Get SG
      SECURITY_GROUP_ID=$(aws elbv2 describe-load-balancers --load-balancer-arns $LOAD_BALANCER_ARN --region $REGION --query 'LoadBalancers[*].SecurityGroups[0]' --output text)
      check_error

      for i in "${!PROTOCOLS[@]}"
      do
          PROTOCOL=${PROTOCOLS[$i]}
          PORT=${PORTS[$i]}

          if [ ${#IPS[@]} -eq 0 ]
          then
              IPS+=("$USER_IP")
          fi

          for IP in "${IPS[@]}"
          do
              if [ "$ACTION" == "add" ]
              then
                  # Add
                  aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol $PROTOCOL --port $PORT --cidr $IP/32 --region $REGION
                  check_error
              elif [ "$ACTION" == "remove" ]
              then
                  # Remove
                  aws ec2 revoke-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol $PROTOCOL --port $PORT --cidr $IP/32 --region $REGION
                  check_error
              fi
          done

      done
    done
fi
