```
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address 192.168.168.40
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3|bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update
helm install cli-nfs-prov --set nfs.server=10.1.14.240 --set nfs.path=/srv stable/nfs-client-provisioner
kubectl apply -f /vagrant/data/nextflow-claim.yaml 
```
