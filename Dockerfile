FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

COPY target/container.demo-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8088

ENTRYPOINT ["java", "-jar", "app.jar"]