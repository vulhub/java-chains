FROM eclipse-temurin:8u432-b06-jdk-jammy

RUN addgroup --system appgroup && adduser --system appuser --ingroup appgroup

WORKDIR /chains

COPY --chown=appuser:appgroup java-chains.jar /chains/java-chains.jar
COPY --chown=appuser:appgroup chains-config/ /chains/chains-config/

USER appuser

EXPOSE 8011 58080 50389 50388 13999 3308 11527 50000

CMD ["java", "-jar", "-Xms512m", "-Xmx2g", "-XX:+UseG1GC", "/chains/java-chains.jar"]
