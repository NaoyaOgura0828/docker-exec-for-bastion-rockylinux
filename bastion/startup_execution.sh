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

setup_authorized_keys ${SYSTEM_NAME}-${ENV_TYPE}-keypair

tail -f /dev/null
