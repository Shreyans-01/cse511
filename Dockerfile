# Base image: ubuntu:22.04
FROM ubuntu:22.04

# ARGs
# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG TARGETPLATFORM=linux/amd64,linux/arm64
ARG DEBIAN_FRONTEND=noninteractive

# neo4j 5.5.0 installation and some cleanup
RUN apt-get update && \
    apt-get install -y wget gnupg software-properties-common curl git openjdk-17-jre && \
    wget -O - https://debian.neo4j.com/neotechnology.gpg.key | apt-key add - && \
    echo 'deb https://debian.neo4j.com stable latest' > /etc/apt/sources.list.d/neo4j.list && \
    add-apt-repository universe && \
    apt-get update && \
    update-java-alternatives --jre --set java-1.17.0-openjdk-amd64 && \
    apt-get install -y nano unzip neo4j=1:5.5.0 python3-pip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*



# TODO: Complete the Dockerfile



RUN pip install pip --upgrade && \
    pip install neo4j pandas pyarrow

RUN neo4j-admin dbms set-initial-password project1phase1 && echo khbnkjnn && \
    sed -i 's/#dbms.connector.bolt.listen_address=:7687/dbms.connector.bolt.listen_address=0.0.0.0:7687/' /etc/neo4j/neo4j.conf && \
    sed -i 's/#server.default_listen_address=0.0.0.0/server.default_listen_address=0.0.0.0/' /etc/neo4j/neo4j.conf && \
    echo 'dbms.routing.enabled=false' >> /etc/neo4j/neo4j.conf && \
    echo 'dbms.security.procedures.unrestricted=gds.*,apoc.*' >> /etc/neo4j/neo4j.conf && \
    echo 'dbms.security.procedures.allowlist=gds.*,apoc.*' >> /etc/neo4j/neo4j.conf

# Download and install the GDS plugin (version 2.3.1)
RUN wget -P /var/lib/neo4j/plugins https://github.com/neo4j/graph-data-science/releases/download/2.3.1/neo4j-graph-data-science-2.3.1.jar


# Clone private GitHub repository
RUN git clone https://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@github.com/Shreyans-01/cse511.git /cse511 && \
    cd cse511 && echo kjhkh && \
    curl -O https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2022-03.parquet

WORKDIR /cse511

# Run the data loader script
RUN chmod +x /cse511/data_loader.py && \
    neo4j start && echo hgnmjhghg && \
    python3 /cse511/data_loader.py && \
    neo4j stop

# Expose neo4j ports
EXPOSE 7474 7687

# Start neo4j service and show the logs on container run
CMD ["/bin/bash", "-c", "neo4j start && tail -f /dev/null"]