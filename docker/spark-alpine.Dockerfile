FROM python:3.13.0-alpine3.20 AS spark-base

# Build arguments for easy version management
ARG SPARK_VERSION=3.5.7
ARG SCALA_VERSION=2.13
ARG DELTA_SPARK_VERSION=3.3.2
ARG SPARK_UID=1000

# Environment variables
ENV SPARK_HOME="/opt/spark" \
    SPARK_VERSION=${SPARK_VERSION} \
    SCALA_VERSION=${SCALA_VERSION} \
    DELTA_SPARK_VERSION=${DELTA_SPARK_VERSION} \
    PATH="/opt/spark/sbin:/opt/spark/bin:${PATH}" \
    SPARK_MASTER="spark://spark-master:7077" \
    SPARK_MASTER_HOST=spark-master \
    SPARK_MASTER_PORT=7077 \
    SPARK_NO_DAEMONIZE=true \
    PYSPARK_PYTHON=python3 \
    PYTHONPATH=$SPARK_HOME/python

ENV SPARK_SUBMIT_ARGS="--packages io.delta:delta-spark_${SCALA_VERSION}:${DELTA_SPARK_VERSION} --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"

# Install runtime dependencies
RUN apk update --no-cache && apk upgrade --no-cache \
    && apk add --no-cache \
        bash \
        curl \
        openjdk17-jre \
        rsync \
        procps \
    && rm -rf /var/cache/apk/* \
    && addgroup -g ${SPARK_UID} spark \
    && adduser -D -u ${SPARK_UID} -G spark -h ${SPARK_HOME} spark \
    && mkdir -p ${SPARK_HOME}/spark-events \
    && chown -R spark:spark ${SPARK_HOME}/spark-events

WORKDIR ${SPARK_HOME}

# Download and verify Spark, then install Python packages
RUN SPARK_DIST="spark-${SPARK_VERSION}-bin-hadoop3-scala${SCALA_VERSION}.tgz" \
    && curl -fsSL "https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/${SPARK_DIST}" -o /tmp/${SPARK_DIST} \
    && curl -fsSL "https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/${SPARK_DIST}.sha512" -o /tmp/${SPARK_DIST}.sha512 \
    && cd /tmp \
    && sha512sum -c ${SPARK_DIST}.sha512 \
    && tar xzf ${SPARK_DIST} --directory ${SPARK_HOME} --strip-components=1 \
    && rm -rf /tmp/${SPARK_DIST}* \
    && chown -R spark:spark ${SPARK_HOME} \
    && pip3 install --no-cache-dir \
        pyspark==${SPARK_VERSION} \
        delta-spark==${DELTA_SPARK_VERSION}

# Copy configuration files with proper permissions
COPY --chown=spark:spark ./spark-defaults.conf ${SPARK_HOME}/conf/spark-defaults.conf
COPY --chown=spark:spark --chmod=755 ./entrypoint.sh ${SPARK_HOME}/entrypoint.sh

# Switch to non-root user
USER spark

ENTRYPOINT ["./entrypoint.sh"]
