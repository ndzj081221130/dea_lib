
cd /vagrant/test/helloworld-jsonrpc
cf push
cf restart proc
cf restart portal
cf delete-force auth_new

