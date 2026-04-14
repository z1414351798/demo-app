kubectl create secret docker-registry regcred \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username=YOUR_USER \
    --docker-password=YOUR_PASS \
    --docker-email=YOUR_EMAIL