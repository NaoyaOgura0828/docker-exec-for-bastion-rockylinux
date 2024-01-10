#!/bin/bash

# Create Users
create_users() {
    USER_LIST="${CREATE_USER_LIST}"

    if [ -z "${USER_LIST}" ]; then
        echo "User list is empty."
    fi

    IFS=', '
    for user_name in ${USER_LIST}; do
        if ! id ${user_name} &> /dev/null; then
            sudo adduser ${user_name} --badname
            sudo cp ~/.bashrc /home/${user_name}/.bashrc
            echo "User name ${user_name} is created."

        else
            echo "User name ${user_name} is already exists."

        fi
    done

    unset IFS

}

# Setup authorized_keys
setup_authorized_keys() {

    USER_LIST="${CREATE_USER_LIST}"

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

    if [ -z "${USER_LIST}" ]; then
        echo "User list is empty."
    fi

    IFS=', '
    for user_name in ${USER_LIST}; do
        sudo mkdir /home/${user_name}/.ssh
        sudo chmod 700 /home/${user_name}/.ssh
        sudo chown ${user_name}:${user_name} /home/${user_name}/.ssh
        sudo cp ~/.ssh/authorized_keys /home/${user_name}/.ssh/authorized_keys
        sudo chown ${user_name}:${user_name} /home/${user_name}/.ssh/authorized_keys
        echo "Setup done authorized_keys for ${user_name}."

    done

    unset IFS

    sudo /usr/sbin/sshd

    rm id_rsa.pem
    rm id_rsa.pub

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

# Delete Admin User
delete_admin_user() {
    if [ ${IS_DELETE_ADMIN_USER} = true ]; then
        (
            sleep 60
            CURRENT_USER=$(whoami)
            sudo userdel -r ${CURRENT_USER}
        ) &
        echo "Delete the admin user after 60 seconds."
    else
        echo "IS_DELETE_ADMIN_USER: false."
    fi

}

create_users
setup_authorized_keys
register_public_ip_to_bastion_domain
delete_admin_user

tail -f /dev/null
