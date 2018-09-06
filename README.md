# OCS Inventory
Current Version: 2.5


Wazuh helps you to gain deeper security visibility into your infrastructure by monitoring hosts at an operating system and application level. This solution, based on lightweight multi-platform agents, provides the following capabilities:

- **Log management and analysis:** Wazuh agents read operating system and application logs, and securely forward them to a central manager for rule-based analysis and storage.
- **File integrity monitoring:** Wazuh monitors the file system, identifying changes in content, permissions, ownership, and attributes of files that you need to keep an eye on.
- **Intrusion and anomaly detection:** Agents scan the system looking for malware, rootkits or suspicious anomalies. They can detect hidden files, cloaked processes or unregistered network listeners, as well as inconsistencies in system call responses.
- **Policy and compliance monitoring:** Wazuh monitors configuration files to ensure they are compliant with your security policies, standards or hardening guides. Agents perform periodic scans to detect applications that are known to be vulnerable, unpatched, or insecurely configured.

This diverse set of capabilities is provided by integrating OSSEC, OpenSCAP and Elastic Stack, making them work together as a unified solution, and simplifying their configuration and management.

Wazuh provides an updated log analysis ruleset, and a RESTful API that allows you to monitor the status and configuration of all Wazuh agents.

Wazuh also includes a rich web application (fully integrated as a Kibana app), for mining log analysis alerts and for monitoring and managing your Wazuh infrastructure.

## Wazuh Open Source components and contributions

* [Wazuh](https://documentation.wazuh.com/current/index.html) was born as a fork of [OSSEC HIDS]
