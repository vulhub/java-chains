FROM eclipse-temurin:8u432-b06-jdk-jammy

RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

WORKDIR /chains

COPY --chown=appuser:appgroup java-chains.jar /chains/java-chains.jar
COPY --chown=appuser:appgroup chains-config/ /chains/chains-config/

# Runtime-writable paths used by FakeMySQL captures / plugins / presets.
# Bind mounts may overlay chains-config; entrypoint then fixes ownership.
RUN mkdir -p /chains/chains-config/cache/fake-server-files \
        /chains/chains-config/plugins \
        /chains/chains-config/presets \
        /chains/chains-config/plugin-data \
    && chown -R appuser:appgroup /chains

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

EXPOSE 8011 58080 50389 50388 13999 3308 11527 50000

# Entrypoint starts as root to repair bind-mount permissions, then drops to appuser.
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["java", "-jar", "-Xms512m", "-Xmx2g", "-XX:+UseG1GC", "/chains/java-chains.jar"]
