#!/bin/bash

CLUSTER_NAME=eks-worker
#your eks cluster name

ACCOUNT_ID=380962557106
#your aws account ID, You can check on AWS 'IAM'

VPC_ID=vpc-0fdcfa9ae5dc1bfa1
#VPC ID

EKS_REGION=ap-northeast-2
#Region with EKS installed

eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} --approve
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.3.1/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json 1> /dev/null


eksctl create iamserviceaccount \
  --cluster=eks-worker \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve


curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
echo 'DOWNLOAD helm_scrpits'
sleep 2
chmod +x get_helm.sh
./get_helm.sh

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=${CLUSTER_NAME} \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set image.repository=602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller \
    --set region=${EKS_REGION} \
    --set vpcId=${VPC_ID}
