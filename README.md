# AWS-CICD


## 참여 인원 👨‍👨‍👧‍👧
| <img src="https://avatars.githubusercontent.com/u/83341978?v=4" width="150" height="150"/> | <img src="https://avatars.githubusercontent.com/u/129728196?v=4" width="150" height="150"/> | <img src="https://avatars.githubusercontent.com/u/104816148?v=4" width="150" height="150"/> | <img src="https://avatars.githubusercontent.com/u/86452494?v=4" width="150" height="150"/> |
|:-------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------:|:-------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------:|
|                     **박지원** <br/>[@jiione](https://github.com/jiione)                     |                      **최나영**<br/>[@na-rong](https://github.com/na-rong)                      |                     **박현서**<br/>[@hyleei](https://github.com/hyleei)                      |                 **백승지** <br/>[@seungji2001](https://github.com/seungji2001)                 |                         |
<br>

--- 
# AWS-CICD-Demo
![image](https://github.com/user-attachments/assets/e4a2d819-44b5-4a84-b859-3312a665bcca)


## 목차
1. [소개](#소개)
2. [아키텍처 구성 요소 및 과정](#아키텍처-구성-요소-및-과정)
   - [Jenkins](#jenkins)
   - [Docker](#docker)
   - [S3](#s3)
   - [EC2](#ec2)
   - [VM](#vm)
3. [배포 프로세스](#배포-프로세스)

---

## 소개
이 문서는 CI/CD 파이프라인을 사용하여 애플리케이션을 AWS 환경에 배포하는 과정을 설명합니다. Jenkins와 Docker를 사용하여 애플리케이션을 빌드하고, AWS S3에 아티팩트를 저장한 후, EC2 인스턴스에 배포합니다.

## 아키텍처 구성 요소 및 과정
### 1. Docker
   - **시나리오**: Jenkins는 Docker 컨테이너 내에서 실행되며, 애플리케이션을 독립적이고 일관된 환경에서 빌드합니다.
```bash
    stage('Clone Repository') {
          steps {
              git branch: 'main', url: 'it'
          }
    }
```
### 2. Jenkins
   - **시나리오**: Jenkins는 코드를 빌드하고, JAR 파일을 생성한 후 S3에 업로드와 EC2에 배포 합니다.
### 3. S3
   - **시나리오**: Jenkins가 빌드한 JAR 파일을 AWS S3에 업로드하여 EC2에서 액세스할 수 있도록 합니다.
### 4. EC2
   - **시나리오**: EC2 인스턴스는 S3에 저장된 JAR 파일을 다운로드하여 애플리케이션을 실행합니다.
   - **명령어**:
     ```bash
     // EC2에서 S3로부터 JAR 파일 다운로드
     aws s3 cp s3://your-bucket-name/SpringApp-0.0.1-SNAPSHOT.jar /home/ubuntu/

     // 애플리케이션을 백그라운드에서 실행
     nohup java -jar /home/ubuntu/SpringApp-0.0.1-SNAPSHOT.jar > /dev/null 2>&1 &
     ```
