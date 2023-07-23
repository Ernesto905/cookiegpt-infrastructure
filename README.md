# CookieGPT-Infrastructure 

## Configuring the cluster locally 

1. Ensure the following command returns the appropriate role
\$ aws sts get-caller-identity 

2. Create or update a kubeconfig for your cluster.Replace region-code with the AWS Region that you created your cluster in. Replace my-cluster with the name of your cluster.
\$ aws eks update-kubeconfig --region region-code --name my-cluster

3. Test the configuration
\$ kubectl get svc
You should get something like this
NAME             TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
svc/kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   1m


## Updating pods without flux

1. Ensure cookiegpt deployment, redis pod, and redis service are not running
\$ kubectl get all 
\$ kubectl delete [pods/deploy] <pod/deployment>

2. Run the pods
\$ kubectl apply -f app-deployment.yaml
\$ kubectl apply -f redis-service.yaml
\$ kubectl apply -f redis.yaml

3. Port forward the cookiegpt pod 
\$ kubectl port-forward [pod name] 5000:5000      

kubectl port-forward [service]

## Setting up secrets

We will be making use of the Kubernetes Secret store CSI Driver to store secrets internally within a kubernetes pod's volume. On the AWS Side, we will be allocating the appropriate conditions to the EKS Cluster through AWS secret and configuration provider (ASCP).

*Pre-req: Have eksctl installed*

1. Install the necessary Helm packages

\$ helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts

\$ helm install -n kube-system csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver

\$ helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws

\$ helm install -n kube-system secrets-provider-aws aws-secrets-manager/secrets-store-csi-driver-provider-aws

2. Ensure cluster has necessary permissions. To check if you already have one on your cluster, click the link below and follow along. Else, just run the shell command below:
https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
\$ eksctl utils associate-iam-oidc-provider --cluster <my-cluster-name> --approve


3. Save the following environmental variables in shell for future use:
\$ REGION=<REGION>
\$ CLUSTERNAME=<CLUSTERNAME>
\$ POLICY_ARN=$(aws --region "$REGION" --query Policy.Arn --output text iam create-policy --policy-name <Deployment-name>-deployment-policy --policy-document '{
    "Version": "2012-10-17",
    "Statement": [ {
        "Effect": "Allow",
        "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        "Resource": ["<SECRETARN>"]
    } ]
}')




4. Create the service account that the pod uses. Associate the policy in the POLICY_ARN env variable with it:
\$ eksctl create iamserviceaccount --name <Deployment-name>-deployment-sa --region="$REGION" --cluster "$CLUSTERNAME" --attach-policy-arn "$POLICY_ARN" --approve --override-existing-serviceaccounts

5. If not already created, create a Secret-provider-class yaml file to configure what secrets will be mounted to what pod. Also update the deployment pod to connect with the secret provider class

6. Run the secret provider class and deployment pod with kubectl apply -f

7. Verify the name has been mounted
\$ kubectl exec -it $(kubectl get pods | awk '/<Deployment-name>-deployment/{print $1}' | head -1) cat /mnt/secrets-store/<Secret-name>; echo


## Updates to source code guide through (WITHOUT FLUX)
At this point, updates to the source code branch (not this one) should automatically be turned into an image and pushed to docker hub. This is done when pushes are made to the main branch.

To reflect the changes here
1. Ensure changes are made to main branch 
gitlab -> view pipelines -> check status

2. Update kubernetes cluster (navigate to /kubernetes)
\$ kubectl delete -f app-deployment
\$ kubectl apply -f app-deployment 

3. Port forward 
\$ kubectl port-forward [pod name] 5000:5000 

4. Navigate to localhost:5000


## Errors? 
Getting an 
"Internal Server Error

The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application."

run 
\$ kubectl logs <pod-name>
and debug ¯\\._(ツ)_./¯

## To delete everything 
To delete the entire infrastructure from aws
1. Delete EKS and VPC hosted on AWS through terraform
\$ terraform destroy

2. In the AWS Console, delete the following accordingly: 
EKS cluster role:
IAM -> Roles -> eksctl-cookiegpt-cluster-addon-iamserviceacc-Role1-B82JWYLW34R4

AWS Secret:
AWS Secret Manager -> Secrets -> openAIAPI key

