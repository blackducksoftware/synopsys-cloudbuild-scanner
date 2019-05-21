<p align="center">
  <img width="25%" height="25%" src="https://www.synopsys.com/content/dam/synopsys/sig-assets/images/BlackDuck_by_Synospsy_onwhite.png">
</p>

## Overview ##

Google Cloud Build is a fully managed continuous integration, delivery, & deployment platform that lets you build, test, and deploy in the cloud. 

Black Duck's Scan Client for Google Cloud Build allows:
 * Automatic identification of Open Source Security, License, and Operational risks during your application build process.
 * Optional Support for writing [Container Analysis](https://cloud.google.com/container-registry/docs/container-analysis) [Notes](https://cloud.google.com/container-registry/docs/container-analysis#note) for [Binary Authorization](https://cloud.google.com/binary-authorization/docs/overview) 


## What is Black Duck? ##

[Black Duck by Synopsys](https://www.synopsys.com/software-integrity/security-testing/software-composition-analysis.html) helps organizations identify and manage open source security, license compliance and operational risks in their application portfolio. Black Duck is powered by the world’s largest open source KnowledgeBase™, which contains information from over 13,000 unique sources, includes support for over 80 programming languages, provides timely and enhanced vulnerability information, and is backed by a dedicated team of open source and security experts. The KnowledgeBase™, combined with the broadest support for platforms, languages and integrations, is why 2,000 organizations worldwide rely on Black Duck to secure and manage open source.

The Black Duck Scan Client for Cloud Build can be integrated in your Cloud Build workflow via the cloud build configuration file. A sample step is below:

```
- name: 'gcr.io/blackduck-dev/google-cloudbuild-scanner'
  secretEnv: [ 'BD_URL', 'BD_TOKEN' ]
  args:
  - '--blackduck.url' # URL for Black Duck Instance
  - '$$BD_URL'
  - '--blackduck.api.token' # API Token for Black Duck instance
  - '$$BD_TOKEN'
  - '--detect.project.name' # Project Name to map the scan to
  - '${_IMAGE_NAME}'
  - '--detect.project.version.name' # Project version to map the scan to
  - '${_IMAGE_TAG}'
  - '--detect.tools' # List of Scanners to Run
  - 'SIGNATURE_SCAN'
  - '--detect.source.path' # Target for Signature Scan
  - '/workspace'
  - '--detect.policy.check.fail.on.severities' # The severity of the policy that breaks the build
  - 'CRITICAL'
  
substitutions: # Substitutions are optional, but effective way to insert information in multiple places
  _IMAGE_NAME: <<container_image_name>>
  _IMAGE_TAG: <<container_tag>>
```
## How does the scan work? ##

The Black Duck Scan Client for Google Cloud Build invokes [Synopsys Detect](https://synopsys.atlassian.net/wiki/x/SYC4Aw).

Synopsys Detect consolidates functionality of various Synopsys scanning tools, making it easy to scan applications using a variety of languages and package managers.

Black Duck's Scan Client for Google Cloud Build is able to run a scan against a build of:

	* Application Source Code 
    * Compiled Binaries


## Limitations ##
There are limitations as to what can be scanned by Synopsys Detect when invoked in Google Cloud Build. Generally, only the following can be scanned:

	* Fat JARs (JAR files containing all dependencies)
	* WAR or TAR files containing all dependencies

When invoked in Google Cloud Build, Synopsys Detect cannot, for example, scan a JAR file that contains source but no dependencies.

## Documentation  ##

Documentation and examples can be found in [Synopsys Partnerships Confluence](https://synopsys.atlassian.net/wiki/spaces/PARTNERS/pages/7471154/Scanning+in+Google+Cloud+Build+using+Synopsys+Detect)
## Contributing ##
This is an unsupported integration, maintained by enthusiastic users excited about Black Duck and Google Cloud. 

Please file all issues against this repository, we will do our best to get to it. :)
