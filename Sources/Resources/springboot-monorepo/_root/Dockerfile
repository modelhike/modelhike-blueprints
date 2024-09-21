# Use a specific version of the OpenJDK as the base image
FROM openjdk:17-jdk-alpine AS build

# Set environment variables
ARG APP_DIR=src
ENV APP_HOME ${APP_DIR}
WORKDIR $APP_HOME

# Copy Gradle wrapper and build files
COPY gradlew build.gradle settings.gradle ./
COPY gradle gradle

# Download dependencies
RUN ./gradlew dependencies --no-daemon

# Copy the source code
COPY src ./src

# Build the application
RUN ./gradlew build -x test --no-daemon

# Use a smaller base image for the runtime environment
FROM openjdk:17-jdk-alpine

# Set environment variables
ENV APP_HOME=/app
WORKDIR $APP_HOME

# Copy the jar file from the build stage
COPY --from=build /app/build/libs/your-app.jar ./app.jar

# Expose the port that the application will run on
EXPOSE 8080

# Run the Spring Boot application
ENTRYPOINT ["java", "-jar", "app.jar"]
