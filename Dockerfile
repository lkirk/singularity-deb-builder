FROM debian:bookworm

RUN \
	set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
        git \
        wget \
        alien \
		&& rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN \
    set -ex; \
    wget -q https://download-ib01.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/s/singularity-3.8.4-1.el8.x86_64.rpm; \
    \
    alien -d singularity-3.8.4-1.el8.x86_64.rpm; \
    mkdir tmp; \
    dpkg-deb -R singularity_3.8.4-2_amd64.deb tmp; \
    rm -r tmp/usr/lib/.build-id; \
    dpkg-deb -b tmp singularity_3.8.4-2_amd64_final.deb

ADD files_before_after.diff .
ADD files_before_after_uninstall.diff .

RUN \
    set -ex; \
    find / -not -path '/proc/*' > files_before.txt; \
    apt install ./singularity_3.8.4-2_amd64_final.deb; \
    find / -not -path '/proc/*' > files_after.txt; \
    apt remove --purge -y singularity; \
    find / -not -path '/proc/*' > files_after_uninstall.txt

RUN \
    set -ex; \
    git diff --no-index files_before.txt files_after.txt | grep -v '^index ' > install_diff.txt; \
    git diff --no-index files_before.txt files_after_uninstall.txt | grep -v '^index ' > uninstall_diff.txt; \
    diff files_before_after.diff install_diff.txt || ( \
        git diff --no-index files_before_after.diff install_diff.txt --color=always; \
        exit 1; \
    ); \
    diff files_before_after_uninstall.diff uninstall_diff.txt || ( \
        git diff --no-index files_before_after_uninstall.diff uninstall_diff.txt --color=always; \
        exit 1; \
    )
        
