die() { echo "$@"; exit 1; }
set -e
servername=`hostname -s`
grep -q "`hostname`$" /etc/hosts || sudo sh -c "echo 127.0.0.1 `hostname` >>/etc/hosts"
if [ ! -d /opt/source ]; then
    [ -d /opt/source ] || mkdir -p /opt/source
    cd /opt/source
    git clone https://github.com/driehuis/fuga-training-scripting-deploy.git
    [ ! -d "$servername" ] && die "No $servername in checked out tree, please fix"
fi
if [ ! -e /vagrant ]; then
    ln -s /opt/source/$servername /vagrant
fi
sudo rsync -rl /vagrant/files/./ /./
[ "`cat /etc/apt/sources.list|wc -l`" = "1" ] || sudo sh -c "echo '# Cleared by $0, using sources.list.d instead' >/etc/apt/sources.list"
distro=trusty
apt_get_auto() {
  sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@"
}
sudo apt-get update -qq
apt_get_auto install python-openstackclient

cd $HOME
apt_get_auto dist-upgrade
