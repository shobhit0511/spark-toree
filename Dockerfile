FROM centos
#FROM ngp011.svl.ibm.com:5000/ngwb/microservicebasepower:latest
RUN yum -y update
#RUN echo "nameserver 8.8.8.8" >> /etc/resolv.conf
#RUN echo "nameserver 8.8.4.4" >> /etc/resolv.conf
#RUN wget ftp://rpmfind.net/linux/Mandriva/official/2007.0/i586/media/contrib/release/apt-0.5.15cnc6-15mdv2007.0.i586.rpm
#RUN rpm -ivh apt*
# Scala related variables.
ARG SCALA_VERSION=2.12.2
ARG SCALA_BINARY_ARCHIVE_NAME=scala-${SCALA_VERSION}
ARG SCALA_BINARY_DOWNLOAD_URL=http://downloads.lightbend.com/scala/${SCALA_VERSION}/${SCALA_BINARY_ARCHIVE_NAME}.tgz

# SBT related variables.
ARG SBT_VERSION=0.13.15
ARG SBT_BINARY_ARCHIVE_NAME=sbt-$SBT_VERSION
ARG SBT_BINARY_DOWNLOAD_URL=https://dl.bintray.com/sbt/native-packages/sbt/${SBT_VERSION}/${SBT_BINARY_ARCHIVE_NAME}.tgz

# Spark related variables.
ARG SPARK_VERSION=2.0.2
ARG SPARK_BINARY_ARCHIVE_NAME=spark-${SPARK_VERSION}-bin-hadoop2.7
ARG SPARK_BINARY_DOWNLOAD_URL=https://d3kbcqa49mib13.cloudfront.net/${SPARK_BINARY_ARCHIVE_NAME}.tgz

# Configure env variables for Scala, SBT and Spark.
# Also configure PATH env variable to include binary folders of Java, Scala, SBT and Spark.
ENV SCALA_HOME  /usr/local/scala
ENV SBT_HOME    /usr/local/sbt
ENV SPARK_HOME  /usr/local/spark
ENV PATH        $JAVA_HOME/bin:$SCALA_HOME/bin:$SBT_HOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH
ENV PYTHONPATH  $SPARK_HOME/python/:$SPARK_HOME/python/lib/py4j-0.10.3-src.zip:$SPARK_HOME/python/lib/pyspark.zip:$PYTHONPATH
# Download, uncompress and move all the required packages and libraries to their corresponding directories in /usr/local/ folder.
RUN yum install -y wget python-devel gcc libffi-devel openssl-devel unzip bzip2 gcc-c++ tar java-1.8.0-openjdk java-1.8.0-openjdk-devel
RUN yum clean all
RUN wget -qO - ${SCALA_BINARY_DOWNLOAD_URL} | tar -xz -C /usr/local/ && \
    wget -qO - ${SBT_BINARY_DOWNLOAD_URL} | tar -xz -C /usr/local/  && \
    wget -qO - ${SPARK_BINARY_DOWNLOAD_URL} | tar -xz -C /usr/local/ && \
    cd /usr/local/ && \
    ln -s ${SCALA_BINARY_ARCHIVE_NAME} scala && \
    ln -s ${SPARK_BINARY_ARCHIVE_NAME} spark && \
    cp spark/conf/log4j.properties.template spark/conf/log4j.properties && \
    sed -i -e s/WARN/ERROR/g spark/conf/log4j.properties && \
    sed -i -e s/INFO/ERROR/g spark/conf/log4j.properties

# We will be running our Spark jobs as `root` user.
USER root

# Working directory is set to the home folder of `root` user.
WORKDIR /root

# Expose ports for monitoring.
# SparkContext web UI on 4040 -- only available for the duration of the application.
# Spark master’s web UI on 8080.
# Spark worker web UI on 8081.
EXPOSE 4040 8080 8081 8888 8989

RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python get-pip.py

COPY *.tar.gz /opt
RUN pip install --upgrade pip
RUN pip install jupyter_kernel_gateway jupyter-console
RUN pip install /opt/toree*.tar.gz
RUN jupyter toree install --spark_home=$SPARK_HOME --spark_opts="--master=local[*]"
#RUN yum install -y git
#RUN pip install "git+https://github.com/jupyter/kernel_gateway_demos.git#egg=nb2kg&subdirectory=nb2kg"
#RUN jupyter serverextension enable --py nb2kg --sys-prefix
CMD ["sh","-c","/bin/jupyter-kernelgateway --ip=* --port=8888 --JupyterWebsocketPersonality.list_kernels=True"]
