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
* [Resources](#resources)


## Overview
OpenShift can be configured to host an EFK stack that stores and indexes log data but at some sites a log aggregation system is already in place. The default OpenShift fluetnd image can be modified to directly forward messages to Splunk.  Currenly the disadvantages of this method are no filter can be done so all messages are sent to Splunk.  

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
output-extra-splunk.conf: |
  <store>
    @type splunk_ex
    host mysplunkserver
    port 9997
    output_format json
  </store>
```

Update the `logging-fluentd` daemonset to use new fluentd image
```yaml
containers:
  - name: fluentd-elasticsearch
    image: 'logging/openshift-fluentd-splunk:latest'
```

Run the following commands to redeploy the fluentd pods.
```bash
oc project logging
oc delete pod -l component=fluentd
```

## Resources
* [Secure Forwarding with Splunk](https://playbooks-rhtconsulting.rhcloud.com/playbooks/operationalizing/secure-forward-splunk.html)
* [Origin Fluentd Image Source](https://github.com/openshift/origin-aggregated-logging/blob/master/fluentd/Dockerfile)
* [Fluentd Filter Plugin Overview](http://docs.fluentd.org/v0.12/articles/filter-plugin-overview)
