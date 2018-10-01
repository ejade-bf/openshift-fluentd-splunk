FROM registry.access.redhat.com/openshift3/logging-fluentd:latest

RUN yum-config-manager --enable rhel-7-server-rpms rhel-7-server-optional-rpms

RUN yum install -y gcc make ruby-devel

RUN gem install -N --conservative --minimal-deps --no-document \
       'activesupport:<5' \
       fluent-plugin-secure-forward \
       fluent-plugin-kubernetes_metadata_filter \
       fluent-plugin-rewrite-tag-filter \
       fluent-plugin-secure-forward \
       fluent-plugin-remote_syslog \
       fluent-plugin-record-modifier \
       fluent-plugin-splunk-enterprise

RUN yum remove gcc make ruby-devel -y

RUN rm -rf /var/cache/yum/*
