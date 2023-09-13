FROM rockylinux:8 

LABEL maintainer="CSC Service Desk <servicedesk@csc.fi>"

# These need to be owned and writable by the root group in OpenShift
ENV ROOT_GROUP_DIRS='/var/run /var/log/nginx /var/lib/nginx'

ARG repo_branch=update-dependencies

RUN yum -y install epel-release &&\
    yum -y install nginx &&\
    yum -y install python3.11 &&\
    yum -y install python3.11-pip &&\
    yum -y install git &&\
    yum -y install findutils &&\
    yum clean all

RUN chgrp -R root ${ROOT_GROUP_DIRS} &&\
    chmod -R g+rwx ${ROOT_GROUP_DIRS}

COPY . /tmp

WORKDIR /tmp


RUN git clone --no-checkout https://github.com/joonas-somero/csc-user-guide git_folder && \
    if [ -d ".git" ]; then rm -r .git; fi && \
    mv git_folder/.git . && \
    rm -r git_folder && \
    git reset HEAD --hard && \
    git checkout -f $repo_branch

RUN pip3 install --no-cache-dir -r requirements.txt && \
    bash scripts/generate_alpha.sh && \
    bash scripts/generate_by_system.sh && \
    bash scripts/generate_new.sh && \
    bash scripts/generate_glossary.sh && \
    mkdocs build -d /usr/share/nginx/html

COPY nginx.conf /etc/nginx

EXPOSE 8000

CMD [ "/usr/sbin/nginx" ]
