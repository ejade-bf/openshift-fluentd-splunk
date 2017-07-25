# OpenShift Fluentd to Splunk

## Table of Contents

* [Overview](#overview)
* [Bill of Materials](#bill-of-materials)
    * [Environment Specifications](#environment-specifications)
* [Setup Instructions](#setup-instructions)
* [Presenter Notes](#presenter-notes)
    * [Environment Setup](#environment-setup)
    * [Create Build Configuration and Image](#create-build-configuration-and-image)
    * [Update Existing ConfigMap](#update-existing-configmap)
    * [Configure Fluentd Loggers](#configure-fluentd-loggers)
    * [Filtering](#filtering)
* [Resources](#resources)


## Overview
OpenShift can be configured to host an EFK stack that stores and indexes log data but at some sites a log aggregation system is already in place. The default OpenShift fluetnd image can be modified to directly forward messages to Splunk.  

## Bill of Materials

### Environment Specifications

This quickstart should be run on an installation of OpenShift Enterprise V3 with an existing EFK deployment.

## Setup Instructions

### Environment Setup

The EFK stack should already be configured in the `logging` namespace.

### Create Build Configuration and Image


Run the following commands to create the build configuration and ImageStream.
```bash
oc project logging
oc new-app registry.access.redhat.com/openshift3/logging-fluentd:latest~https://github.com/themoosman/openshift-fluentd-splunk.git
```

### Update Existing ConfigMap

Add the following section to the ConfigMap to create a new splunk configuration file.  
Update the host with the correct Splunk hostname.

```yaml
splunk.conf: |
  <filter kubernetes.**>
    @type record_modifier
    enable_ruby yes
    auto_typecast yes
    <record>
      forwarded_by "#{ENV['HOSTNAME']}"
      source_component "OCP"
    </record>
  </filter>

  <match kubernetes.**>
    @type splunk_ex
    host mysplunkserver
    port 9997
    output_format json
  </match>

  <match **>
    @type null
  </match>
```

Edit the fluent.conf section of the ConfigMap to add a reference to the new splunk.conf file.
```yaml
  ## matches
  @include configs.d/openshift/output-pre-*.conf
  @include configs.d/openshift/output-operations.conf
  @include configs.d/user/splunk.conf
  @include configs.d/openshift/output-applications.conf
  ## no post - applications.conf matches everything left
  ##
```

Update the `logging-fluentd` daemonset to use new fluentd image
```yaml
containers:
  - name: fluentd-elasticsearch
    image: 'logging/openshift-fluentd-splunk:latest'
```

Run the following commands to redeploy the fluentd pods.
```bash[Public Domain](#public-domain)
* [License](#license)
oc project logging
oc delete pod -l component=fluentd
```

### Filtering
In some use cases it might be necessary to perform filtering at the external fluentd process.  This would be done to reduce the number or type of messages that are forwared.  

Using the fluentd.conf file from above a new record will be added to the json message.  The record `kubernetes_namespace_name` will be set to the OpenShift namespace from where the messages originated.

Using the appened records, a filter is applied to all messages.  Messages where `kubernetes_namespace_name` match the specified regex pattern `devnull|logging|default|openshift|openshift-infra|management-infra|kube-system|prometheus` are dropped and not forwared on.  

```yaml
data:
  splunk.conf: |
    <filter kubernetes.**>
      @type record_transformer
      enable_ruby yes
      auto_typecast yes
      <record>
        kubernetes_namespace_name ${record["kubernetes"]["namespace_name"].nil? ? 'devnull' : record["kubernetes"]["namespace_name"]}
        forwarded_by "#{ENV['HOSTNAME']}"
        source_component "OCP"
      </record>
    </filter>

    #Run filter on kube messages
    <filter kubernetes.**>
      @type grep
      #Always filter out the restricted namespaces
      exclude1 kubernetes_namespace_name (devnull|logging|default|openshift|openshift-infra|management-infra|kube-system|prometheus)
    </filter>

    <match kubernetes.**>
      @type splunk_ex
      host mysplunkserver
      port 9997
      output_format json
    </match>

    #Toss the rest of the records.
    <match **>
      @type null
    </match>
```
## Resources
* [Secure Forwarding with Splunk](https://playbooks-rhtconsulting.rhcloud.com/playbooks/operationalizing/secure-forward-splunk.html)
* [Origin Fluentd Image Source](https://github.com/openshift/origin-aggregated-logging/blob/master/fluentd/Dockerfile)
* [Fluentd Filter Plugin Overview](http://docs.fluentd.org/v0.12/articles/filter-plugin-overview)
