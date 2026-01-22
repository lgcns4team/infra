#!/bin/bash
set -eux # 에러 발생 시 즉시 중단 및 실행된 명령 출력. 실행된 명령도 출력되어 디버깅에 도움.

echo "--- User Data script started (Instance type: t2.micro) ---"
echo "Starting package update and utility installation..."

# RDS 서버 시간대는 정상, EC2 Ubunt 서버 시간대는 UTC > Asia/Seoul 문제 해결
sudo timedatectl set-timezone Asia/Seoul
sudo timedatectl set-ntp true

# 1. 패키지 목록 업데이트 및 필요한 유틸리티 설치
#    sudo는 User Data 스크립트가 기본적으로 root 권한으로 실행되므로 apt-get에 필수는 아니지만, 명시적 사용.
#    apt-get update 실패 시 1회 재시도 (t2.micro와 같은 저사양 인스턴스에서 간혹 발생)
sudo apt-get update -y || (sleep 10 && sudo apt-get update -y)
sudo apt-get install -y ruby wget zip jq ca-certificates curl gnupg lsb-release

echo "--- Essential utilities installed ---"


# 2. Docker 설치
echo "--- Installing Docker ---"
# Docker 공식 GPG 키 추가 및 repository 설정
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  \"$(. /etc/os-release && echo "$VERSION_CODENAME")\" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker 패키지 설치
sudo apt-get update -y || (sleep 10 && sudo apt-get update -y)
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 'ubuntu' 사용자를 docker 그룹에 추가하여 sudo 없이 docker 명령 실행 가능하게 함
sudo usermod -aG docker ubuntu

echo "--- Docker installed successfully ---"


echo "--- Installing CodeDeploy Agent ---"

sudo apt-get update -y
sudo apt-get install -y ruby wget

cd /tmp
wget https://aws-codedeploy-ap-northeast-2.s3.ap-northeast-2.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto

sudo systemctl enable codedeploy-agent
sudo systemctl restart codedeploy-agent

echo "--- CodeDeploy Agent installed ---"


# 3. CodeDeploy Agent 설치
echo "--- Installing CodeDeploy Agent ---"
# 'codedeploy-agent.service' 파일이 이미 존재하는지 확인하여 불필요한 재설치 방지
if ! systemctl status codedeploy-agent.service &> /dev/null; then
    echo "CodeDeploy Agent not found, installing..."
    cd /tmp
    wget https://aws-codedeploy-ap-northeast-2.s3.ap-northeast-2.amazonaws.com/latest/install
    chmod +x ./install
    sudo ./install auto # CodeDeploy Agent 설치
    rm -f install

    # 설치 후 systemd 데몬 재로드 및 서비스 활성화/시작
    sudo systemctl daemon-reload || echo "systemctl daemon-reload failed, continuing..."
    sudo systemctl enable codedeploy-agent.service || echo "Failed to enable CodeDeploy Agent service, continuing..."
    sudo systemctl start codedeploy-agent.service || echo "Failed to start CodeDeploy Agent service, continuing..."

    echo "CodeDeploy Agent installation script executed."
else
    echo "CodeDeploy Agent is already installed and running."
fi

echo "--- CodeDeploy Agent installation process completed ---"


# 4. SSM Agent 확인 및 상태 확인
echo "--- Checking SSM Agent status ---"
if ! systemctl is-active --quiet snap.amazon-ssm-agent.amazon-ssm-agent.service; then
    echo "SSM Agent not running, installing/restarting..."
    # snap install 명령에도 오류 대비
    sudo snap install core --classic || echo "snap install core failed, continuing..."
    sudo snap refresh core || echo "snap refresh core failed, continuing..."
    sudo snap install amazon-ssm-agent --classic || echo "snap install amazon-ssm-agent failed, continuing..."
    sudo systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service || echo "Failed to enable SSM Agent service, continuing..."
    sudo systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service || echo "Failed to start SSM Agent service, continuing..."
else
    echo "SSM Agent is already running."
fi
echo "--- SSM Agent status checked ---"


# 5. 'ubuntu' 사용자가 비밀번호 없이 sudo를 사용할 수 있도록 설정 (SSM 접속 문제 해결)
#    /etc/sudoers.d/ 에 파일을 추가하는 방식으로 안전하게 설정
echo "--- Configuring passwordless sudo for 'ubuntu' user ---"
echo "ubuntu ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/90-ubuntu-nopasswd > /dev/null
sudo chmod 0440 /etc/sudoers.d/90-ubuntu-nopasswd # sudoers 파일 보안 권한 설정
echo "--- Passwordless sudo configured for 'ubuntu' user ---"


# 6. 최종 서비스 상태 확인 (로그 출력을 통해 명확하게)
echo "--- Final Service Status Check ---"
echo "CodeDeploy Agent Status:"
sudo systemctl status codedeploy-agent.service --no-pager || echo "CodeDeploy Agent service is not active or failed to check."
echo "SSM Agent Status:"
sudo systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service --no-pager || echo "SSM Agent service is not active or failed to check."
echo "Docker Status:"
sudo systemctl status docker.service --no-pager || echo "Docker service is not active or failed to check."

echo "--- User Data script finished ---"