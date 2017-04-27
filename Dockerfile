FROM isuper/java-oracle:jre_8

# This is a hack to fix a rogue JRE_HOME variable set in the isuper/java-oracle
ENV JRE_HOME ""
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

# see https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/KEYS
ENV GPG_KEYS 05AB33110949707C93A279E3D3EFE6B686867BA6 07E48665A34DCAFAE522E5E6266191C37C037D42 47309207D818FFD8DCD3F83F1931D684307A10A5 541FBE7D8F78B25E055DDEE13C370389288584E7 61B832AC2F1C5A90F0F9B00A1C506407564C17A3 713DA88BE50911535FE716F5208B0AB1D63011C7 79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED 9BA44C2621385CB966EBA586F72C284D731FABEE A27677289986DB50844682F8ACB77FC2E86E29AC A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23
RUN set -ex; \
        for key in $GPG_KEYS; do \
                gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
        done

ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.0.42

# https://issues.apache.org/jira/browse/INFRA-8753?focusedCommentId=14735394#comment-14735394
#ENV TOMCAT_TGZ_URL http://ftp.ps.pl/pub/apache/tomcat/tomcat-8/v8.0.42/bin/apache-tomcat-8.0.42.tar.gz
ENV TOMCAT_TGZ_URL http://ftp.ps.pl/pub/apache/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz
# not all the mirrors actually carry the .asc files :'(
ENV TOMCAT_ASC_URL https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc

RUN set -x \
        && curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
        && curl -fSL "$TOMCAT_ASC_URL" -o tomcat.tar.gz.asc \
        && gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz \
        && tar -xvf tomcat.tar.gz --strip-components=1 \
        && rm bin/*.bat \
        && rm tomcat.tar.gz*

RUN apt-get update
RUN apt-get install vim -y

# Deploy test application
ADD test.war /usr/local/tomcat/webapps

ADD setenv.sh /usr/local/tomcat/bin
ADD tomcat-users.xml /usr/local/tomcat/conf
EXPOSE 8080 7590 9590

# Launch Tomcat
CMD ["bin/catalina.sh", "run"]
