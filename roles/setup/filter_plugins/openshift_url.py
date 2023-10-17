from __future__ import (absolute_import, division, print_function)
__metaclass__ = type


import urllib.request
import re


class FilterModule(object):

    def filters(self):
        'Define filters'
        return {
            'cluster_base_version': self.cluster_base_version,
            'product_release_version': self.product_release_version,
        }

    def cluster_base_version(self, cluster_version):
        """
        Get Openhsift base version based on cluster version

        :param cluster_version: Version of openshift
        """
        # Possible inputs:
        # 4.10.28
        # stable-4.9
        # latest-4.11
        # ...

        if 'latest' in cluster_version or 'stable' in cluster_version:
            cluster_base_version = cluster_version.split('-')[1]
        else:
            version_split = cluster_version.split('.')
            cluster_base_version = version_split[0] + '.' + version_split[1]
        return cluster_base_version
    
    def product_release_version(self, cluster_version):
        """
        Get the product release version based on cluster version (ie latest-4.10)

        :param openshift_version: Version of openshift to get OVA
        """
        clients_content = "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/{}/sha256sum.txt".format(cluster_version)

        response = urllib.request.urlopen(clients_content)
        content = response.read().decode('utf-8')

        # openshift-install-linux - must be always there, so find its version:
        version_pattern = r"openshift-install-linux-(\d+\.\d+\.\d+)\.tar\.gz"

        matches = re.findall(version_pattern, content)

        for match in matches:
            return match