# Arguments and non-interactive mode
FROM ubuntu:22.04

ARG TARGETPLATFORM=linux/amd64,linux/arm64
ARG DEBIAN_FRONTEND=noninteractive

# Install Neo4j, Python3, and other necessary packages
RUN apt-get update && \
    apt-get install -y wget gnupg software-properties-common && \
    wget -O - https://debian.neo4j.com/neotechnology.gpg.key | apt-key add - && \
    echo 'deb https://debian.neo4j.com stable latest' > /etc/apt/sources.list.d/neo4j.list && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y nano unzip neo4j=1:5.5.0 python3-pip git && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Clone private GitHub repository
RUN git clone https://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@github.com/Shreyans-01/cse511.git

WORKDIR /cse511

# Download the dataset
RUN wget -O /var/lib/neo4j/import/yellow_tripdata_2022-03.parquet "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2022-03.parquet"

# Upgrade pip and install required Python packages
RUN pip3 install --upgrade pip && \
    pip3 install neo4j pandas pyarrow

# Set up Neo4j password and configuration for external connections
RUN echo "dbms.default_listen_address=0.0.0.0" >> /etc/neo4j/neo4j.conf && \
    echo "dbms.connector.bolt.listen_address=0.0.0.0:7687" >> /etc/neo4j/neo4j.conf && \
    echo "dbms.connector.http.listen_address=0.0.0.0:7474" >> /etc/neo4j/neo4j.conf && \
    neo4j-admin set-initial-password project1phase1

# Run the data loader script
RUN chmod +x /cse511/data_loader.py && \
    neo4j start && \
    python3 /cse511/data_loader.py && \
    neo4j stop

# Expose Neo4j ports
EXPOSE 7474 7687

# Start Neo4j service and keep container running
CMD ["/bin/bash", "-c", "neo4j start && tail -f /dev/null"]