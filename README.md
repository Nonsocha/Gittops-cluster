## ADVANCE GITOPS TECHNIQUES
**Introduction**
 In this project we to focus on real world applications like multi-cluster deployment,microservices archetecture,and integrating ArgoCD into CI/CD pipelines, This project should help individuals handle complex Kubernates deployment and understand how Gitops principle works in different scenario

 ### Deploye Multi-Cluster Microservice Architectures With ArgoCD

**Objective**

Deploy applications across multiple Kubernetes clusters and manage microservices using ArgoCD.

### 1. Set Up Multi-Cluster Environment

### 1.1 Create Multiple Kubernetes Clusters

**Using AWS EKS (Production-like)**
eksctl create cluster --name cluster1
eksctl create cluster --name cluster2

**1.2 Verify Clusters**
```
kubectl config get-contexts
```
Before then connect kubectl with eks cluster.

```
aws eks update-kubeconfig \
  --region us-east-1 \
  --name cluster1
```
**Test Connection**

Switch between cluster:

kubectl config use-context cluster1 

 kubectl config use-context cluster2

 Note:When trying to switch cluster it will be denied permission.Add this to your .bashrc so it never breaks again:
 ```
 echo 'export KUBECONFIG=$HOME/.kube/config' >> ~/.bashrc
source ~/.bashrc
```
 **Check again**
   ```
   kubectl config get-contexts
  ``` 
 ### 2. Install ArgoCD (On One Cluster)

 ```
 kubectl create namespace argocd

 kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
 ```

 Check pods:
```
kubectl get pods -n argocd
```

### 2.1 Access ArgoCD with CLI
**1 Port-forward ArgoCD server**

**Run**
```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Keep this terminal OPEN (don’t close it)

**Login again (in another terminal)**

```
argocd login localhost:8080 --insecure
```

**Get admin password**
```
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

**After Login Works**
```
argocd cluster add cluster1
argocd cluster add cluster2
```

**Verify cluster list**
```
argocd cluster list
```

### 4. Structure Your Microservices Repository
You need a GitHub repo that ArgoCD will use.

#### 4.1 Create a repo (locally or GitHub)

```
mkdir my-app
cd my-app
```

**Create folder structure**
```
mkdir service-a service-b overlays
mkdir overlays/dev overlays/prod
```
Now create files:
```
touch service-a/deployment.yaml
touch service-a/service.yaml

touch service-b/deployment.yaml
touch service-b/service.yaml
```

#### 4.3 Example Kubernetes YAML (Service A)
service-a/deployment.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-a
spec:
  replicas: 2
  selector:
    matchLabels:
      app: service-a
  template:
    metadata:
      labels:
        app: service-a
    spec:
      containers:
      - name: service-a
        image: nginx
        ports:
        - containerPort: 80
 ```       

 service-a/service.yaml

 ```
 apiVersion: v1
kind: Service
metadata:
  name: service-a
spec:
  selector:
    app: service-a
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
 ``` 

 Do same for service-b (just change names)

####  4.4 Push to GitHub

```
git init
git add .
git commit -m "initial microservices setup"
git remote add origin https://github.com/YOUR_USERNAME/my-app.git
git push -u origin main
```
### 5. Create ArgoCD Applications

Create file:

```
touch app-cluster1.yaml
```

```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-cluster1
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/my-app.git
    targetRevision: HEAD
    path: service-a
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
  ```    

  **5.2 Apply it**
```
kubectl apply -f app-cluster1.yaml
```

**5.3 Create app for cluster2**

- First switch cluster

```
kubectl config use-context cluster2
```

Now Create:

```
touch app-cluster2.yaml
```
```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-cluster2
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/my-app.git
    targetRevision: HEAD
    path: service-b
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
  ```    

  ```
  kubectl apply -f app-cluster2.yaml
  ```

### Verify Deployment
```
kubectl get pods
kubectl get svc
```  

### STEP 6: Multi-Cluster Setup in ArgoCD

### Step 6.1: Make sure you are logged into ArgoCD

First, ensure port-forward is running:

```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Open new terminal:

```
argocd login localhost:8080 --insecure
```


### Step 6.2: Add both clusters to ArgoCD

- This is the MOST IMPORTANT step

Add cluster1
```
kubectl config use-context cluster1
argocd cluster add cluster1
```
Add cluster2

```
kubectl config use-context cluster2
argocd cluster add cluster2
```

### Step 6.3: Verify clusters

```
cluster1
cluster2
```
Note: Always use the command below to tell kubctl to use kubeconfig instead of k83
```
echo 'export KUBECONFIG=$HOME/.kube/config' >> ~/.bashrc
source ~/.bashrc
```
#### STEP 6.4: Deploy to BOTH clusters

Now you create two applications

App for cluster1

```
destination:
  server: https://kubernetes.default.svc
 ``` 

 **App for cluster2**

Create:
```
nano app-cluster2.yaml
```
```apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-cluster2
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Nonsocha/Gittops-cluster.git
    targetRevision: HEAD
    path: service-b
  destination:
    server: https://<CLUSTER2-API-SERVER>
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
 ```     

 **Get cluster2 API server**
```
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
```
Copy the output:

```
https://A95625E88BDAD64C149DCA04C52B3DD8.gr7.us-east-1.eks.amazonaws.com
```
Replace in YAML:
```
server:https://A95625E88BDAD64C149DCA04C52B3DD8.gr7.us-east-1.eks.amazonaws.com
```

Apply it:
```
kubectl apply -f app-cluster2.yaml
```
**Verify Deployment**
Cluster1
```
kubectl config use-context cluster1
kubectl get pods
```
**Cluster**
```
kubectl config use-context cluster1
kubectl get pods
```

### 7. Sync Applications

Using CLI:

```
argocd app sync app-cluster1
argocd app sync app-cluster2

Or use ArgoCD UI → Click Sync
```

### 8. Verify Deployment
```
kubectl get pods
kubectl get svc

Check per cluster:

kubectl config use-context cluster1
kubectl get pods
```