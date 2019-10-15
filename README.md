# Attention Network for Text Summarization on Kubeflow

Presented at O'Reilly Artificial Intelligence Conference London :  "Deep learning and attention networks all the way to production" https://conferences.oreilly.com/artificial-intelligence/ai-eu/public/schedule/detail/78072


## Authors
1. Pramod Singh
2. Akshay Kulkarni 


## Highlights of the session :

<ol>
<li>Overview of Attention Networks ( What and Why )</li>
<li>Set Up GCP Environment</li>
<li>Attention Networks for text summarization</li>
<li>How to leverage Kubeflow for Industrialization</li>
<ol>
<li>Setup Kubeflow on GCP </li>
<li>Use TensorFlow 2.0 to create attention network</li>
<li>Use Kubeflow Notebook Server for training </li>
<li>Containerize model for training at scale </li>
<li>Save the trained model at GCS </li>
</ol>
</li>
<li>Challenges and Future Work</li>
</ol>


   


## Research Papers

[Pascal Vincent, Hugo Larochelle, Isabelle Lajoie, Yoshua Bengio, and Pierre-
Antoine Manzagol. “Stacked denoising autoencoders: Learning useful representations
in a deep network with a local denoising criterion”]

[Alan Akbik, Duncan Blythe and Roland Vollgraf ,”Contextual String Embeddings for Sequence Labeling” ]



# Step-By-Step Guide for Running Attention Network on Kubeflow

1. Access the Code - Clone the github repo into your google cloud shell 

```
git clone https://github.com/pramodsinghwalmart/AI_Conf_London.git

```
   
2. Navigate to code directory

```
cd AI_Conf_London

```

3. Set current working directory

```
WORKING_DIR=$(pwd)

```

4. Setup Kubeflow in GCP

Make sure you have gcloud SDK is installed and pointing to the right GCP PROJECT. You can use 'gcloud init' to perform this action.
    
```
gcloud components install kubectl

```

5. Setup environment variables
    
```
export PROJECT=<PROJECT_ID>

```

```
export DEPLOYMENT_NAME=kubeflow

```

```
export ZONE=us-central1-a

```


```
gcloud config set project ${PROJECT}

```


```
gcloud config set compute/zone ${ZONE}

```


6. Use one-click deploy interface by GCP to setup kubeflow using https://deploy.kubeflow.cloud/#/ . Just fill Deployment Name (kubeflow) and Project ID and select appropriate GCP Zone(us-central1-a) . You can select Login with username and password to access Kubeflow service.Once the deployment is completed, you can connect to the cluster.

7. Connecting to the cluster

```
gcloud container clusters get-credentials ${DEPLOYMENT_NAME} \
--project ${PROJECT_ID} \
--zone ${ZONE}

```


8. Set context and create a namespace

```
kubectl config set-context $(kubectl config current-context) --namespace=kubeflow

```


```
kubectl get all

```


9. Install Kustomize 
Kubeflow makes use of kustomize to help manage deployments.We have the version 2.0.3 of kustomize available in the folder already.This tutorial does not work with later versions of kustomize, due to bug /kustomize/issues/1295.

```
cd kustomize

```

```
mv kustomize_2.0.3_linux_amd64 kustomize

```

```
chmod u+x kustomize

```

```
cd ..

```

add ks command to path


```
PATH=$PATH:$(pwd)/kustomize

```


check if kustomize installed properly 


```
kustomize version

```


10. Allow docker to access our GCR registry

```
gcloud auth configure-docker --quiet

```


11. Create GCS bucket for model storage

```
cd training/GCS

```

```
export BUCKET=${PROJECT}-${DEPLOYMENT_NAME}-bucket

```

```
gsutil mb -c regional -l us-central1 gs://${BUCKET}

```



12. Build Training Image using docker and push to GCR

```
export TRAIN_IMG_PATH=gcr.io/${PROJECT}/${DEPLOYMENT_NAME}-train:latest

```


build the tensorflow model into a container

```
docker build $WORKING_DIR -t $TRAIN_IMG_PATH -f $WORKING_DIR/Dockerfile

```

push container to GCR

```
docker push ${TRAIN_IMG_PATH}

```


13. Prepare the training component to run on GKE using kustomize

Give the job a name so that you can identify it later

```
kustomize edit add configmap attention   --from-literal=name=attention-training

```



Configure the custom training image


```
kustomize edit add configmap  attention  --from-literal=imagename=gcr.io/${PROJECT}/${DEPLOYMENT_NAME}-train

```


```
kustomize edit set image training-image=${TRAIN_IMG_PATH}

```


Set the training parameters (training steps, batch size and learning rate). Note - We are going to declare these parameters using kustomize but we are not using any of these for this tutorial purpose.



```
kustomize edit add configmap attention --from-literal=trainSteps=200

```


```
kustomize edit add configmap attention --from-literal=batchSize=100

```


```
kustomize edit add configmap attention --from-literal=learningRate=0.01

```

Configure parameters and save the model to Cloud Storage



```
kustomize edit add configmap attention --from-literal=modelDir=gs://${BUCKET}

```


```
kustomize edit add configmap attention --from-literal=exportDir=gs://${BUCKET}/export

```

14. Check the permissions for your training component 
You need to ensure that your Python code has the required permissions to read/write to your Cloud Storage bucket. Kubeflow solves this by creating a user service account within your project as a part of the deployment. You can use the following command to list the service accounts for your Kubeflow deployment



```
gcloud iam service-accounts list | grep ${DEPLOYMENT_NAME}

```


Kubeflow granted the user service account the necessary permissions to read and write to your storage bucket. Kubeflow also added a Kubernetes secret named user-gcp-sa to your cluster, containing the credentials needed to authenticate as this service account within the cluster


```
kubectl describe secret user-gcp-sa

```


To access your storage bucket from inside the train container, you must set the GOOGLE_APPLICATION_CREDENTIALS environment variable to point to the JSON file contained in the secret. Set the variable by passing the following parameters


```
kustomize edit add configmap attention --from-literal=secretName=user-gcp-sa

```

```
kustomize edit add configmap attention --from-literal=secretMountPath=/var/secrets

```


```
kustomize edit add configmap attention --from-literal=GOOGLE_APPLICATION_CREDENTIALS=/var/secrets/user-gcp-sa.json

```


15. Train the model on GKE

```
kustomize build .

```

```
kustomize build . |kubectl apply -f -

```

```
kubectl logs -f attention-training-chief-0

```

16. Check the saved model at the GCS bucket/export location 

17. Clean up resources 

Delete the deployement 
```
gcloud deployment-manager --project=${PROJECT} deployments delete ${DEPLOYMENT_NAME}

```


Delete the docker image 
```
gcloud container images delete gcr.io/$PROJECT/${DEPLOYMENT_NAME}-train:latest

```


Delete the bucket 
```
gsutil rm -r gs://${BUCKET}

```

