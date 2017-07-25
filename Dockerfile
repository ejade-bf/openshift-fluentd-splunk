FROM registry.access.redhat.com/openshift3/logging-fluentd:latest

RUN gem install -N --conservative --minimal-deps --no-document \
      'activesupport:<5' \
      fluent-plugin-secure-forward \
      fluent-plugin-kubernetes_metadata_filter \
      fluent-plugin-rewrite-tag-filter \
      fluent-plugin-secure-forward \
      fluent-plugin-remote_syslog \
      fluent-plugin-record-modifier \
      fluent-plugin-splunk-ex
