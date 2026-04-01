FROM eclipse-temurin:8u432-b06-jdk-jammy

RUN addgroup --system appgroup && adduser --system appuser --ingroup appgroup

WORKDIR /chains

ARG TARGETARCH

COPY --chown=appuser:appgroup java-chains.jar /chains/java-chains.jar
COPY --chown=appuser:appgroup chains-config/ /chains/chains-config/
COPY --chown=appuser:appgroup mcp-binaries/ /chains/mcp-binaries/

RUN set -eux; \
    case "${TARGETARCH}" in \
      "amd64") MCP_BIN="java-chains-mcp-linux-amd64" ;; \
      "arm64") MCP_BIN="java-chains-mcp-linux-arm64" ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    cp "/chains/mcp-binaries/${MCP_BIN}" /chains/java-chains-mcp; \
    chmod +x /chains/java-chains-mcp; \
    ln -sf /chains/java-chains-mcp /usr/local/bin/java-chains-mcp; \
    rm -rf /chains/mcp-binaries

USER appuser

CMD ["java","-jar","-Xms512m","-Xmx2g","-XX:+UseG1GC","/chains/java-chains.jar"]
