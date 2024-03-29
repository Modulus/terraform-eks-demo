DOWNLOAD_URL=$(curl -Ls "https://api.github.com/repos/kubernetes-sigs/metrics-server/releases/latest" | jq -r .tarball_url)
DOWNLOAD_VERSION=$(grep -o '[^/v]*$' <<< $DOWNLOAD_URL)
curl -Ls $DOWNLOAD_URL -o /tmp/metrics-server-$DOWNLOAD_VERSION.tar.gz
mkdir /tmp/metrics-server-$DOWNLOAD_VERSION
tar -xzf /tmp/metrics-server-$DOWNLOAD_VERSION.tar.gz --directory /tmp/metrics-server-$DOWNLOAD_VERSION --strip-components 1
cp -Rv /tmp/metrics-server-$DOWNLOAD_VERSION/deploy/1.8+/ k8s/kustomize/bases/metrics-server/$DOWNLOAD_VERSION

#kubectl apply -f /tmp/metrics-server-$DOWNLOAD_VERSION/deploy/1.8+/