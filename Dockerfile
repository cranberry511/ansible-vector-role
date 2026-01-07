FROM pycontribs/centos:7
ENV MOLECULE_NO_LOG=false

ENV container=docker

RUN INSTALL_PKGS='findutils initscripts iproute python sudo' \
    && sed -i 's/mirror.centos.org/vault.centos.org/g' /etc/yum.repos.d/*.repo \
    && sed -i 's/^#.*baseurl=http/baseurl=http/g' /etc/yum.repos.d/*.repo \
    && sed -i 's/^mirrorlist=http/#mirrorlist=http/g' /etc/yum.repos.d/*.repo \
    && yum makecache fast && yum install -y $INSTALL_PKGS \
    && yum makecache fast && yum update -y \
    && yum clean all


COPY rpm .
RUN yum install -y *.rpm
RUN rm -f *.rpm

RUN find /etc/systemd/system \
    /lib/systemd/system \
    -path '*.wants/*' \
    -not -name '*journald*' \
    -not -name '*systemd-tmpfiles*' \
    -not -name '*systemd-user-sessions*' \
    -print0 | xargs -0 rm -vf



RUN yum reinstall glibc-common -y
RUN yum update -y && yum install tar gcc make python3-pip zlib-devel openssl-devel yum-utils libffi-devel -y
RUN yum install wget perl -y
RUN wget https://www.openssl.org/source/openssl-1.1.1g.tar.gz
RUN tar -xvf openssl-*.tar.gz && rm -f openssl-*.tar.gz && cd openssl-* && ./config --prefix=/usr --openssldir=/usr && make && make install
COPY Python-3.7.10.tgz .
RUN tar xf Python-3.7.10.tgz && cd Python-3.7.10/ && ./configure && make && make altinstall
COPY Python-3.9.2.tgz .
RUN tar xf Python-3.9.2.tgz && cd Python-3.9.2/ && ./configure && make && make altinstall
RUN python3 -m pip install --upgrade pip && pip3 install tox selinux
RUN rm -rf Python-*
RUN yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
RUN yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
RUN systemctl enable docker
RUN pip3 install "molecule==3.4.0" && pip3 install molecule_docker
RUN pip3 install "ansible-lint<6.0.0" && pip3 install flake8
RUN ln -s /opt/vector-role/.tox/py37-ansible30/bin/python3 /usr/bin/python3.7
RUN ln -s /opt/vector-role/.tox/py39-ansible30/bin/python3 /usr/bin/python3.9

ENTRYPOINT [ "/usr/sbin/init" ]
