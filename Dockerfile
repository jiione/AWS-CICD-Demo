# 베이스 이미지 설정
FROM openjdk:17-jdk-slim

# 작업 디렉터리 설정
WORKDIR /app

# JAR 파일을 컨테이너에 복사
COPY target/spring-app.jar /app/spring-app.jar

# 컨테이너가 시작될 때 실행할 명령어 설정
ENTRYPOINT ["java", "-jar", "/app/spring-app.jar"]

# 기본 포트 설정
EXPOSE 80