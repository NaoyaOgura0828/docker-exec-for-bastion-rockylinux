#!/bin/bash

# Setup authorized_keys
setup_authorized_keys() {
    KEY_PAIR_NAME=$1

    KEY_PAIR_ID=$(aws ec2 describe-key-pairs \
        --filters Name=key-name,Values=${KEY_PAIR_NAME} \
        --query KeyPairs[*].KeyPairId \
        --output text)

    aws ssm get-parameter \
        --name /ec2/keypair/${KEY_PAIR_ID} \
        --with-decryption \
        --query Parameter.Value \
        --output text > id_rsa.pem

    chmod 600 id_rsa.pem

    ssh-keygen -yf id_rsa.pem > id_rsa.pub

    cat ~/id_rsa.pub >> ~/.ssh/authorized_keys

    chmod 600 ~/.ssh/authorized_keys

    rm id_rsa.pem
    rm id_rsa.pub

    sudo /usr/sbin/sshd

}

# Register PublicIP to Bastion Domain
register_public_ip_to_bastion_domain() {
    PUBLIC_IP=$(curl http://checkip.amazonaws.com/)

    BASTION_DOMAIN_ID=$(
        aws route53 list-hosted-zones-by-name \
            --dns-name bastion.${PARENT_NAKED_DOMAIN} \
            --query "HostedZones[0].Id" \
            --output text |
            awk -F'/' '{print $3}'
    )

    IS_BASTION_DOMAIN_A_RECORD_SET=$(
        aws route53 list-resource-record-sets \
            --hosted-zone-id ${BASTION_DOMAIN_ID} \
            --query "ResourceRecordSets[?Type=='A']" \
            --output text |
            wc -w
    )

    if [ ${IS_BASTION_DOMAIN_A_RECORD_SET} != 0 ]; then
        aws route53 change-resource-record-sets \
            --hosted-zone-id ${BASTION_DOMAIN_ID} \
            --change-batch \
            "{
                \"Changes\": [
                    {
                        \"Action\": \"UPSERT\",
                        \"ResourceRecordSet\": {
                            \"Name\": \"bastion.${PARENT_NAKED_DOMAIN}\",
                            \"Type\": \"A\",
                            \"TTL\": 300,
                            \"ResourceRecords\": [
                                {
                                    \"Value\": \"${PUBLIC_IP}\"
                                }
                            ]
                        }
                    }
                ]
            }" > /dev/null

    else
        aws route53 change-resource-record-sets \
            --hosted-zone-id ${BASTION_DOMAIN_ID} \
            --change-batch \
            "{
                \"Changes\": [
                    {
                        \"Action\": \"CREATE\",
                        \"ResourceRecordSet\": {
                            \"Name\": \"bastion.${PARENT_NAKED_DOMAIN}\",
                            \"Type\": \"A\",
                            \"TTL\": 300,
                            \"ResourceRecords\": [
                                {
                                    \"Value\": \"${PUBLIC_IP}\"
                                }
                            ]
                        }
                    }
                ]
            }" > /dev/null

    fi

}

setup_authorized_keys ${SYSTEM_NAME}-${ENV_TYPE}-keypair
register_public_ip_to_bastion_domain

tail -f /dev/null
