# AWS-CICD 구축


## 참여 인원 👨‍👨‍👧‍👧
| <img src="https://avatars.githubusercontent.com/u/83341978?v=4" width="150" height="150"/> | <img src="https://avatars.githubusercontent.com/u/129728196?v=4" width="150" height="150"/> | <img src="https://avatars.githubusercontent.com/u/104816148?v=4" width="150" height="150"/> | <img src="https://avatars.githubusercontent.com/u/86452494?v=4" width="150" height="150"/> |
|:-------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------:|:-------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------:|
|                     **박지원** <br/>[@jiione](https://github.com/jiione)                     |                      **최나영**<br/>[@na-rong](https://github.com/na-rong)                      |                     **박현서**<br/>[@hyleei](https://github.com/hyleei)                      |                 **백승지** <br/>[@seungji2001](https://github.com/seungji2001)                 |                         |
<br>

--- 
# AWS-CICD-Demo
![image](https://github.com/user-attachments/assets/f39f6386-296a-4182-a873-59287d65e10f)


## 📋 목차

1. [프로젝트 개요](#-프로젝트-개요)
2. [사전 요구 사항](#-사전-요구-사항)
3. [Jenkins 파이프라인 구성](#-jenkins-파이프라인-구성)
4. [Dockerfile 작성](#-dockerfile-작성)
5. [Jenkins 파이프라인 스크립트](#-jenkins-파이프라인-스크립트)
6. [Watchtower 설정](#-watchtower-설정)
7. [애플리케이션 배포](#-애플리케이션-배포)
8. [문제 해결](#-문제-해결)
9. [향후 개선 사항](#-향후-개선-사항)

## 🎯 프로젝트 개요

Spring Boot 애플리케이션의 개발부터 배포까지의 과정을 자동화하는 것입니다. 주요 구성 요소는 다음과 같습니다:

- **🍃 Spring Boot**: Java 기반의 웹 애플리케이션
- **🛠️ Jenkins**: CI/CD 파이프라인 관리
- **🐳 Docker**: 애플리케이션 컨테이너화
- **🏪 Docker Hub**: 컨테이너 이미지 저장소
- **🔄 Watchtower**: 컨테이너 자동 업데이트

## 📚 사전 요구 사항

- ☕ Java JDK 17
- 🐘 Gradle
- 🌿 Git
- 🛠️ Jenkins
- 🐳 Docker
- 🏪 Docker Hub 계정
- ☁️ AWS EC2 인스턴스 (또는 다른 호스팅 서비스)

## 🔧 Jenkins 파이프라인 구성

1. Jenkins 대시보드에서 새로운 파이프라인 작업을 생성합니다.
2. GitHub 저장소와 연결하여 소스 코드 관리를 설정합니다.
3. Jenkinsfile을 사용하여 파이프라인을 정의합니다.

## 📄 Dockerfile 작성

```dockerfile
FROM openjdk:17-jdk-alpine
WORKDIR /app
COPY build/libs/*.jar app.jar
ENTRYPOINT ["java","-jar","/app/app.jar"]
```

## 📜 Jenkins 파이프라인 스크립트

```groovy
pipeline {
    agent any
    environment {
        DOCKER_IMAGE_NAME = 'hyleei/spring-app'
        DOCKER_CREDENTIALS_ID = 'hyleei'
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}"
        TRIVY_HOME = "${JENKINS_HOME}/trivy"
        GRADLE_OPTS = '-Dorg.gradle.daemon=false -Dorg.gradle.parallel=true -Dorg.gradle.caching=true'
    }
    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/jiione/AWS-CICD-Demo.git'
            }
        }
        stage('Set Permissions') {
            steps {
                sh 'chmod +x ./gradlew'
            }
        }
        stage('Build JAR') {
            steps {
                sh './gradlew clean build --no-daemon'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}", "--no-cache .")
                }
            }
        }
        stage('Run Trivy Scan') {
            steps {
                script {
                    sh """
                        if ! command -v ${TRIVY_HOME}/trivy &> /dev/null; then
                            echo "Trivy not found. Installing..."
                            mkdir -p ${TRIVY_HOME}
                            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b ${TRIVY_HOME}
                        fi
                        ${TRIVY_HOME}/trivy image --no-progress --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                    """
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', "${DOCKER_CREDENTIALS_ID}") {
                        def imageExists = sh(script: "docker manifest inspect ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} > /dev/null 2>&1", returnStatus: true) == 0
                        
                        if (!imageExists) {
                            echo "Image ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} does not exist. Pushing..."
                            
                            def startTime = System.currentTimeMillis()
                            
                            dockerImage.push("${DOCKER_IMAGE_TAG}")
                            
                            def latestDigest = sh(script: "docker inspect --format='{{index .RepoDigests 0}}' ${DOCKER_IMAGE_NAME}:latest 2>/dev/null || echo ''", returnStdout: true).trim()
                            def newDigest = sh(script: "docker inspect --format='{{index .RepoDigests 0}}' ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}", returnStdout: true).trim()
                            
                            if (latestDigest != newDigest) {
                                echo "Updating latest tag..."
                                dockerImage.push("latest")
                            } else {
                                echo "Latest tag is up to date. Skipping push."
                            }
                            
                            def endTime = System.currentTimeMillis()
                            def duration = (endTime - startTime) / 1000
                            echo "Push took ${duration} seconds"
                        } else {
                            echo "Image ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} already exists. Skipping push."
                        }
                    }
                }
            }
        }
        stage('Cleanup') {
            steps {
                sh "docker rmi ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} || true"
                sh "docker rmi ${DOCKER_IMAGE_NAME}:latest || true"
                cleanWs()
            }
        }
    }
    post {
        success {
            echo "Pipeline completed successfully."
        }
        failure {
            echo "Pipeline failed. Please check the logs for more information."
        }
    }
}
```

![image](https://github.com/user-attachments/assets/484b611f-6293-4322-877c-883323568843)


## 🔄 Watchtower 설정

Watchtower를 사용하여 컨테이너 자동 업데이트를 구성합니다:

```bash
docker run -d \
  --name watchtower \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --interval 300 \
  spring-app
```

## 🚀 애플리케이션 배포

1. EC2 인스턴스에 Docker를 설치합니다.
2. Spring Boot 애플리케이션 컨테이너를 실행합니다:

```bash
docker run -d --name spring-app -p 80:80 chinarong2/spring-app:latest
```

3. Watchtower를 실행하여 자동 업데이트를 활성화합니다.

![image](https://github.com/user-attachments/assets/ca828a05-8ade-4f7b-a8a3-44881d030e60)
![image](https://github.com/user-attachments/assets/86912d20-6c50-4cf4-8d2f-e63a8c8a8814)


## 🔍 문제 해결

1. Jenkins 빌드 실패
   - 문제: Gradle 빌드 중 "Permission denied" 오류 발생
   - 해결: Gradle Wrapper에 실행 권한 부여
     ```bash
     chmod +x gradlew
     ```

2. Docker 이미지 빌드 실패
   - 문제: Docker 빌드 중 "context canceled" 오류 발생
   - 해결: Docker 데몬 재시작
     ```bash
     sudo service docker restart
     ```

3. Docker Hub 푸시 실패
   - 문제: 인증 오류로 이미지 푸시 실패
   - 해결: Jenkins에서 Docker Hub 자격 증명 재설정

4. 컨테이너 포트 매핑 문제
   - 문제: 애플리케이션에 접근할 수 없음
   - 해결: 컨테이너 재시작 with 올바른 포트 매핑
     ```bash
     docker stop spring-app
     docker rm spring-app
     docker run -d --name spring-app -p 80:80 chinarong2/spring-app:latest
     ```

5. Watchtower 업데이트 감지 실패
   - 문제: 새 이미지 푸시 후 자동 업데이트 안 됨
   - 해결: Watchtower 로그 확인 및 재시작
     ```bash
     docker logs watchtower
     docker restart watchtower
     ```

6. EC2 인스턴스 연결 문제
   - 문제: SSH를 통한 EC2 연결 실패
   - 해결: 보안 그룹 설정 확인 및 수정 (SSH 포트 22 열기)

7. 애플리케이션 로그 확인
   - 문제: 애플리케이션 오류 발생
   - 해결: 컨테이너 로그 확인
     ```bash
     docker logs spring-app
     ```

## 🔮 향후 개선 사항

- 🧪 자동화된 테스트 추가
- 📊 모니터링 및 로깅 개선
- 🔐 보안 강화
- 🔧 다중 환경 (개발, 스테이징, 프로덕션) 설정

     
