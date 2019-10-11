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
<code>git clone git clone https://github.com/pramodsinghwalmart/AI_Conf_London.gitnano</code>.

navigate to code directory
cd AI_Conf_London

set current working directoery
WORKING_DIR=$(pwd)

2. Setup Kubeflow in GCP
Make sure you have gcloud SDK is installed and pointing to the right GCP PROJECT. You can use gcloud init to perform this action.

gcloud components install kubectl

Setup environment variables

export DEPLOYMENT_NAME=<CHOOSE_ANY_DEPLOYMENT_NAME>
export PROJECT_ID=<YOUR_GCP_PROJECT_ID>
export ZONE=<YOUR_GCP_ZONE>
gcloud config set project ${PROJECT_ID}
gcloud config set compute/zone ${ZONE}
Use one-click deploy interface by GCP to setup kubeflow using https://deploy.kubeflow.cloud/#/ . Just fill Deployment Name and Project ID and select appropriate GCP Zone. You can select Login with username and password to access Kubeflow service.Once the deployment is completed. You can connect to the cluster.

Connecting to the cluster
gcloud container clusters get-credentials ${DEPLOYMENT_NAME} \
  --project ${PROJECT_ID} \
  --zone ${ZONE}

Set context

kubectl config set-context $(kubectl config current-context) --namespace=kubeflow
kubectl get all

3. Experiments in Jupyter Notebook ( Single/ Multiple GPUs)
If you want to use GPUs for your training process. You can add GPU backed Node pool in the Kubernetes Cluster

4. Install Kustomize 


cd kustomize
mv kustomize_2.0.3_linux_amd64 kustomize
chmod u+x kustomize
cd ..

//add ks command to path

PATH=$PATH:$(pwd)/kustomize

// check if kustomize working 
kustomize version




//allow docker to access our GCR registry
gcloud auth configure-docker --quiet

cd jupyter-image && make build PROJECT_ID=$PROJECT_ID && cd ..
cd jupyter-image && make push PROJECT_ID=$PROJECT_ID && cd ..

Use Notebooks in Ambassador UI for running your experiments. Select custom image and set the image name that you just created. You can set the resources and GPUs.

Upload the notebook available capsnet-text-classification.ipynb in notebooks subfolder inside the code directory.


6. 
cd training/GCS
export BUCKET=${PROJECT}-${DEPLOYMENT_NAME}-bucket
gsutil mb -c regional -l us-central1 gs://${BUCKET}



5. Build Train Image
Build Image
export TRAIN_IMG_PATH=gcr.io/${PROJECT}/${DEPLOYMENT_NAME}-train:latest


//build the tensorflow model into a container
//container is tagged with its eventual path on GCR, but it stays local for now
docker build $WORKING_DIR -t $TRAIN_IMG_PATH -f $WORKING_DIR/Dockerfile

Check locally
docker run -it ${TRAIN_IMG_PATH}
Push Docker image to GCR
//allow docker to access our GCR registry
gcloud auth configure-docker --quiet

//push container to GCR
docker push ${TRAIN_IMG_PATH}

6. Training on Kubeflow

check service account access
gcloud --project=$PROJECT iam service-accounts list | grep $DEPLOYMENT_NAME
check kubernetes secrets
kubectl describe secret user-gcp-sa
Set Google Application Credentials

Train on the cluster
// set the parameters for this job

kustomize edit add configmap attention   --from-literal=name=pramod

kustomize edit set image training-image=${TRAIN_IMG_PATH}


kustomize edit add configmap attention --from-literal=trainSteps=200
kustomize edit add configmap attention --from-literal=batchSize=100
kustomize edit add configmap attention --from-literal=learningRate=0.01

kustomize edit add configmap attention --from-literal=modelDir=gs://${BUCKET}
kustomize edit add configmap attention --from-literal=exportDir=gs://${BUCKET}/export


kustomize edit add configmap attention --from-literal=secretName=user-gcp-sa
kustomize edit add configmap attention --from-literal=secretMountPath=/var/secrets


kustomize edit add configmap attention --from-literal=GOOGLE_APPLICATION_CREDENTIALS=/var/secrets/user-gcp-sa.json

kustomize build .
kustomize build . |kubectl apply -f -

