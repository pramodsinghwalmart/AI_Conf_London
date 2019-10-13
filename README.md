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


   


# Research Papers

Text Summarization Using Attention Networks
Investigating Capsule Networks with Dynamic Routing for Text Classification

# Github Repos

We have modified and adapted from following implementation and focused more on Kubeflow implementation for scalibility and performance.

Capsnet with Pure Keras
Capsnet for NLP with Keras
Capsule Text Classification

# Step-By-Step Guide for Running  Attention Network on Kubeflow

1. Access the Code - Clone the github repo

    ```
    git clone https://github.com/pramodsinghwalmart/AI_Conf_London.git

    ```
   
2. Navigate to code directory

    <code>
        cd AI_Conf_London
    </code>

3. set current working directory

    <code>
        WORKING_DIR=$(pwd)
    </code>

4. Setup Kubeflow in GCP

    Make sure you have gcloud SDK is installed and pointing to the right GCP PROJECT. You can use gcloud init to perform this action.
    
    <code>
        gcloud components install kubectl
    </code>

5. Setup environment variables
    '''
    <code>
        export PROJECT=<PROJECT_ID>
    </code>


    <code>
        export DEPLOYMENT_NAME=kubeflow
    </code>



    <code>
        export ZONE=us-central1-a
    </code>





    <code>
        gcloud config set project ${PROJECT}
    </code>




    <code>
        gcloud config set compute/zone ${ZONE}
    </code>


6. Use one-click deploy interface by GCP to setup kubeflow using https://deploy.kubeflow.cloud/#/ . Just fill Deployment Name (kubeflow) and Project ID and select appropriate GCP Zone(us-central1-a) . You can select Login with username and password to access Kubeflow service.Once the deployment is completed. You can connect to the cluster.

7. Connecting to the cluster

    <code>
        gcloud container clusters get-credentials ${DEPLOYMENT_NAME} \
    </code>
    <code>
        --project ${PROJECT_ID} \
    </code>
    <code>
        --zone ${ZONE}
    </code>
    

8. Set context

    <code>
        kubectl config set-context $(kubectl config current-context) --namespace=kubeflow
    </code>




    <code>
        kubectl get all
    </code>


9. Install Kustomize 
    Kubeflow makes use of kustomize to help manage deployments.We have the version 2.0.3 of kustomize available in the folder already.This tutorial does not work with later versions of kustomize, due to bug /kustomize/issues/1295.

    <code>
        cd kustomize
    </code>




    <code>
        mv kustomize_2.0.3_linux_amd64 kustomize
    </code>




    <code>
        chmod u+x kustomize
    </code>




    <code>
        cd ..
    </code>

    add ks command to path



    <code>
        PATH=$PATH:$(pwd)/kustomize
    </code>



    check if kustomize working 



    <code>
        kustomize version
    </code>


10. Allow docker to access our GCR registry

    <code>
        gcloud auth configure-docker --quiet
    </code>


11. Create GCS bucket for model storage

    <code>
        cd training/GCS
    </code>



    <code>
        export BUCKET=${PROJECT}-${DEPLOYMENT_NAME}-bucket
    </code>




    <code>
        gsutil mb -c regional -l us-central1 gs://${BUCKET}
    </code>



12. Build Training Image using docker and push to GCR

    <code>
        export TRAIN_IMG_PATH=gcr.io/${PROJECT}/${DEPLOYMENT_NAME}-train:latest
    </code>


    build the tensorflow model into a container

    <code>
        docker build $WORKING_DIR -t $TRAIN_IMG_PATH -f $WORKING_DIR/Dockerfile
    </code>

    push container to GCR

    <code>
        docker push ${TRAIN_IMG_PATH}
    </code>


13. Prepare the training component to run on GKE using kustomize

    Give the job a name so that you can identify it later

    <code>
        kustomize edit add configmap attention   --from-literal=name=attention-training
    </code>



    Configure the custom training image




    <code>
        kustomize edit add configmap  attention  --from-literal=imagename=gcr.io/${PROJECT}/${DEPLOYMENT_NAME}-train
    </code>




    <code>
        kustomize edit set image training-image=${TRAIN_IMG_PATH}
    </code>



    Set the training parameters (training steps, batch size and learning rate). Note - We are going to declare these parameters using kustomize but we are not using any of these for this tutorial purpose.



    <code>
        kustomize edit add configmap attention --from-literal=trainSteps=200
    </code>



    <code>
        kustomize edit add configmap attention --from-literal=batchSize=100
    </code>



    <code>
        kustomize edit add configmap attention --from-literal=learningRate=0.01
    </code>

    Configure parameters and save the model to Cloud Storage



    <code>
        kustomize edit add configmap attention --from-literal=modelDir=gs://${BUCKET}
    </code>




    <code>
        kustomize edit add configmap attention --from-literal=exportDir=gs://${BUCKET}/export
    </code>

14. Check the permissions for your training component 
    You need to ensure that your Python code has the required permissions to read/write to your Cloud Storage bucket. Kubeflow solves this by creating a user service account within your project as a part of the deployment. You can use the following command to list the service accounts for your Kubeflow deployment



    <code>
        gcloud iam service-accounts list | grep ${DEPLOYMENT_NAME}
    </code>




    Kubeflow granted the user service account the necessary permissions to read and write to your storage bucket. Kubeflow also added a Kubernetes secret named user-gcp-sa to your cluster, containing the credentials needed to authenticate as this service account within the cluster


    <code>
        kubectl describe secret user-gcp-sa
    </code>



    To access your storage bucket from inside the train container, you must set the GOOGLE_APPLICATION_CREDENTIALS environment variable to point to the JSON file contained in the secret. Set the variable by passing the following parameters



    <code>
        kustomize edit add configmap attention --from-literal=secretName=user-gcp-sa
    </code>




    <code>
        kustomize edit add configmap attention --from-literal=secretMountPath=/var/secrets
    </code>




    <code>
        kustomize edit add configmap attention --from-literal=GOOGLE_APPLICATION_CREDENTIALS=/var/secrets/user-gcp-sa.json
    </code>


15. Train the model on GKE

    <code>
        kustomize build .
    </code>


    <code>
        kustomize build . |kubectl apply -f -
    </code>

    <code>
        kubectl logs -f attention-training-chief-0
    </code>

16. Check the saved model at the GCS bucket/export location 

17. Clean up resources 

    Delete the deployement 
    <code>
        gcloud deployment-manager --project=${PROJECT} deployments delete ${DEPLOYMENT_NAME}
    </code>



    Delete the docker image 
    <code>
        gcloud container images delete gcr.io/$PROJECT/${DEPLOYMENT_NAME}-train:latest
    </code>




    Delete the bucket 
    <code>
        gsutil rm -r gs://${BUCKET_NAME}
    </code>

