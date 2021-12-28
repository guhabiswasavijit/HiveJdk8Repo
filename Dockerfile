FROM dockette/jdk8:latest
LABEL maintainer="Avijit GuhaBiswas <guhabiswas.avijit@gmail.com>"
LABEL name="admin/hive-jdk8"

RUN apk add --no-cache bash wget openssh-server openssh-client vim sudo curl tar openrc\
    && adduser --disabled-password --home /home/admin --shell /bin/bash admin\
	&& echo 'admin ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
	
USER root
RUN echo "root:root" | chpasswd
RUN mkdir -p /data/hdfs-nfs/
RUN mkdir -p /opt/bin
WORKDIR /opt
RUN curl -L https://archive.apache.org/dist/hadoop/core/hadoop-3.3.1/hadoop-3.3.1.tar.gz -s -o - | tar -xzf -
RUN mv hadoop-3.3.1 hadoop
ENV HIVE_VERSION=${HIVE_VERSION:-3.1.2}
RUN curl -L https://archive.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz | tar -xzf -
RUN mv apache-hive-$HIVE_VERSION-bin hive

ENV HADOOP_HOME /opt/hadoop
RUN echo "export HDFS_NAMENODE_USER=admin" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh &&\
    echo "export HDFS_DATANODE_USER=admin" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh &&\
	echo "export HDFS_SECONDARYNAMENODE_USER=admin" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh &&\
	echo "export JAVA_HOME=/usr/lib/jvm/default-jvm" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh &&\
	echo "export HADOOP_HOME=/opt/hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh	
	
COPY core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
COPY hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml

ENV PATH /opt/hadoop/bin:/opt/hadoop/sbin:$PATH
ENV HIVE_HOME /opt/hive
ENV PATH $HIVE_HOME/bin:$PATH

	
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys


ADD conf/hive-site.xml $HIVE_HOME/conf
ADD conf/hive-env.sh $HIVE_HOME/conf
ADD conf/hive-log4j2.properties $HIVE_HOME/conf
ADD conf/beeline-log4j2.properties $HIVE_HOME/conf
ADD conf/hive-exec-log4j2.properties $HIVE_HOME/conf
ADD lib/mysql-connector-java-8.0.27.jar $HIVE_HOME/lib/mysql-connector-java-8.0.27.jar
RUN hdfs namenode -format && hdfs dfs -mkdir -p /user/hive/warehouse

WORKDIR /opt/bin
ADD startup.sh startup.sh
RUN chmod 777 startup.sh

EXPOSE 22
EXPOSE 10000
EXPOSE 10001 
EXPOSE 10002
ENTRYPOINT ["startup.sh"]

CMD hive
