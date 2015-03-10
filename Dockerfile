#
#  From this base-image / starting-point
#
FROM debian:testing

#
#  Authorship
#
MAINTAINER ss34@sanger.ac.uk

#
# Pull in packages from testing
#
# RUN echo "deb http://http.debian.net/debian testing main" > \
#      /etc/apt/sources.list && \
#    apt-get update -q -q

#
# Install dependencies
#
RUN apt-get install build-essential hmmer lua5.1 ncbi-blast+ snap \
                    unzip cpanminus mummer infernal exonerate \
                    --yes --force-yes && \
                    cpanm --force Carp Storable Bio::SearchIO List::Util \
                    Getopt::Long && \
                    rm -rf /root/.cpanm/work/

#
# Install AUGUSTUS (binaries)
#
ADD http://bioinf.uni-greifswald.de/augustus/binaries/augustus-3.0.3.tar.gz /opt/augustus-3.0.3.tar.gz
RUN cd /opt && \
    tar -xzvf augustus* && \
    rm -rf *.tar.gz && \
    mv augustus* augustus && \
    rm -rf augustus/docs

#
# Install GenomeTools (most recent git master)
#
ADD https://github.com/genometools/genometools/archive/master.zip /opt/genometools-master.zip
RUN cd /opt && \
    unzip genometools-master.zip && \
    cd /opt/genometools-master && \
    make -j3 cairo=no curses=no && \
    make -j3 cairo=no curses=no install && \
    cd / && \
    rm -rf /opt/genometools-master*

#
# Install ARAGORN
# (this is done from source instead of Debian b/c Debian-built version hangs)
#
ADD http://mbio-serv2.mbioekol.lu.se/ARAGORN/Downloads/aragorn1.2.36.tgz /opt/aragorn.tgz
RUN cd /opt && \
    tar -xvf aragorn.tgz && \
    mv aragorn1* aragorn && \
    cd aragorn && \
    gcc -O2 -o aragorn aragorn*.c

#
# Install and configure OrthoMCL
#
ADD http://www.orthomcl.org/common/downloads/software/unsupported/v1.4/ORTHOMCL_V1.4_mcl-02-063.tar /opt/omcl.tar
RUN cd /opt && \
    tar -xvf omcl.tar && \
    tar -xzvf mcl-02-063.tar.gz && \
    rm -f omcl.tar mcl-02-063.tar.gz && \
    cd /opt/mcl-* && \
    ./configure && \
    make -j3 && \
    make install && \
    cd / && \
    rm -rf /opt/mcl*
RUN sed -i 's/our .PATH_TO_ORTHOMCL.*=.*/our $PATH_TO_ORTHOMCL = ".\/";/' /opt/ORTHOMCLV1.4/orthomcl_module.pm && \
    sed -i 's/our .BLASTALL.*=.*/our $BLASTALL = "\/usr\/bin\/blastall";/' /opt/ORTHOMCLV1.4/orthomcl_module.pm && \
    sed -i 's/our .FORMATDB.*=.*/our $FORMATDB = "\/usr\/bin\/formatdb";/' /opt/ORTHOMCLV1.4/orthomcl_module.pm && \
    sed -i 's/our .MCL.*=.*/our $MCL = "\/usr\/local\/bin\/mcl";/' /opt/ORTHOMCLV1.4/orthomcl_module.pm

#
# get GO OBO file
#
ADD http://geneontology.org/ontology/go.obo /opt/go.obo

#
# get Pfam pHMMs
#
RUN mkdir -p /opt/pfam
ADD http://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz /opt/pfam/Pfam-A.hmm.gz
RUN cd /opt/pfam && \
    gunzip Pfam-A.hmm.gz && \
    hmmpress Pfam-A.hmm && \
    rm -f Pfam-A.hmm

#
# copy data dir
#
RUN mkdir -p /opt/data
ADD ./data /opt/data

#
# install RATT (keep up to date from build directory)
#
ADD ./RATT /opt/RATT

#
# install ABACAS (keep up to date from build directory)
#
ADD ./ABACAS2 /opt/ABACAS2

ENV AUGUSTUS_CONFIG_PATH /opt/augustus/config
ENV RATT_HOME /opt/RATT
ENV GT_RETAINIDS yes
ENV PERL5LIB /opt/ORTHOMCLV1.4/:/opt/RATT/:/opt/ABACAS2/:$PERL5LIB
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/augustus/bin:/opt/augustus/scripts:/opt/ORTHOMCLV1.4:/opt/RATT:/opt/ABACAS2:/opt/aragorn:$PATH
