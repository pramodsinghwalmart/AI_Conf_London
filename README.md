# Attention Network for Text Summarization on Kubeflow

Presented at O'Reilly Artificial Intelligence Conference London :  "Deep learning and attention networks all the way to production" https://conferences.oreilly.com/artificial-intelligence/ai-eu/public/schedule/detail/78072

## Highlights of the session :

<ol>
<li>Overview of Attention Networks ( What and Why )</li>
<li>Set Up GCP Environment</li>
<li>Attention Networks for text summarization</li>
<li>How to leverage Kubeflow for Industrialization</li>
<ol>
<li>Setup Kubeflow on GCP with Multi GPU Support enabled</li>
<li>Use TensorFlow 2.0 to create attention network</li>
<li>Use Kubeflow Notebook Server for training on K8S cluster</li>
</ol>
</li>
<li>Challenges and Future Work</li>
</ol>


   


## Research Papers

Text Summarization Using Attention Networks
Investigating Capsule Networks with Dynamic Routing for Text Classification

## Github Repos

We have modified and adapted from following implementation and focused more on Kubeflow implementation for scalibility and performance.

Capsnet with Pure Keras
Capsnet for NLP with Keras
Capsule Text Classification

Step-By-Step Guide for Running CapsNet on Kubeflow
1. Get the Code
Clone the github repo
<code>
git clone git clone https://github.com/pramodsinghwalmart/AI_Conf_London.git
</code>

navigate to code directory
<code>
cd AI_Conf_London
</code>

set current working directory
<code>
WORKING_DIR=$(pwd)
</code>

2. Setup Kubeflow in GCP
Make sure you have gcloud SDK is installed and pointing to the right GCP PROJECT. You can use gcloud init to perform this action.

<code>
gcloud components install kubectl
</code>

Setup environment variables

<code>export DEPLOYMENT_NAME=<CHOOSE_ANY_DEPLOYMENT_NAME></code>
<code>export PROJECT_ID=<YOUR_GCP_PROJECT_ID></code>
<code>export ZONE=<YOUR_GCP_ZONE></code>
<code>gcloud config set project ${PROJECT_ID}</code>
<code>gcloud config set compute/zone ${ZONE}</code>
Use one-click deploy interface by GCP to setup kubeflow using https://deploy.kubeflow.cloud/#/ . Just fill Deployment Name and Project ID and select appropriate GCP Zone. You can select Login with username and password to access Kubeflow service.Once the deployment is completed. You can connect to the cluster.

Connecting to the cluster
<code>gcloud container clusters get-credentials ${DEPLOYMENT_NAME} \
  --project ${PROJECT_ID} \
  --zone ${ZONE}
  </code>

Set context

<code>kubectl config set-context $(kubectl config current-context) --namespace=kubeflow</code>
<code>kubectl get all</code>

3. Experiments in Jupyter Notebook ( Single/ Multiple GPUs)
If you want to use GPUs for your training process. You can add GPU backed Node pool in the Kubernetes Cluster

4. Install Kustomize 


<code>cd kustomize</code>
<code>mv kustomize_2.0.3_linux_amd64 kustomize</code>
<code>chmod u+x kustomize</code>
<code>cd ..</code>

//add ks command to path

<code>PATH=$PATH:$(pwd)/kustomize</code>

// check if kustomize working 
<code>kustomize version</code>





//allow docker to access our GCR registry
<code>gcloud auth configure-docker --quiet


6. 
<code>cd training/GCS</code>
<code>export BUCKET=${PROJECT}-${DEPLOYMENT_NAME}-bucket</code>
<code>gsutil mb -c regional -l us-central1 gs://${BUCKET}</code>



5. Build Train Image

Build Image
<code>export TRAIN_IMG_PATH=gcr.io/${PROJECT}/${DEPLOYMENT_NAME}-train:latest</code>


//build the tensorflow model into a container
//container is tagged with its eventual path on GCR, but it stays local for now
<code>docker build $WORKING_DIR -t $TRAIN_IMG_PATH -f $WORKING_DIR/Dockerfile</code>

Check locally
<code>docker run -it ${TRAIN_IMG_PATH}</code>


//push container to GCR
<code>docker push ${TRAIN_IMG_PATH}</code>

6. Training on Kubeflow

check service account access
gcloud --project=$PROJECT iam service-accounts list | grep $DEPLOYMENT_NAME
check kubernetes secrets
kubectl describe secret user-gcp-sa
Set Google Application Credentials

Train on the cluster
// set the parameters for this job

<code>kustomize edit add configmap attention   --from-literal=name=pramod</code>

<code>kustomize edit set image training-image=${TRAIN_IMG_PATH}</code>


<code>kustomize edit add configmap attention --from-literal=trainSteps=200</code>
<code>kustomize edit add configmap attention --from-literal=batchSize=100</code>
<code>kustomize edit add configmap attention --from-literal=learningRate=0.01</code>

<code>kustomize edit add configmap attention --from-literal=modelDir=gs://${BUCKET}</code>
<code>kustomize edit add configmap attention --from-literal=exportDir=gs://${BUCKET}/export</code>


<code>kustomize edit add configmap attention --from-literal=secretName=user-gcp-sa</code>
<code>kustomize edit add configmap attention --from-literal=secretMountPath=/var/secrets</code>


<code>kustomize edit add configmap attention --from-literal=GOOGLE_APPLICATION_CREDENTIALS=/var/secrets/user-gcp-sa.json</code>

<code>kustomize build .</code>
<code>kustomize build . |kubectl apply -f -</code>

<code>kubectl logs -f pramod-chief-0</code>