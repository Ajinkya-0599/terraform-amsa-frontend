# 🌟 AMSA Website   

<p align="center">
  <img src="https://img.shields.io/badge/Project-AMSA%20Website-blue?style=for-the-badge&logo=github">
  <img src="https://img.shields.io/badge/Frontend-Next.js-black?style=for-the-badge&logo=next.js">
  <img src="https://img.shields.io/badge/Backend-Node.js-green?style=for-the-badge&logo=node.js">
  <img src="https://img.shields.io/badge/Deployed%20On-AWS%20EC2-orange?style=for-the-badge&logo=amazonaws">
  <img src="https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-blue?style=for-the-badge&logo=githubactions">
  <img src="https://img.shields.io/badge/Process%20Manager-PM2-yellow?style=for-the-badge&logo=pm2">
  <img src="https://img.shields.io/badge/Reverse%20Proxy-Nginx-green?style=for-the-badge&logo=nginx">
  <img src="https://img.shields.io/badge/Infrastructure-AWS%20CloudFormation-red?style=for-the-badge&logo=amazonaws">
  <img src="https://img.shields.io/badge/Monitoring-AWS%20CloudWatch-purple?style=for-the-badge&logo=amazoncloudwatch">
  <img src="https://img.shields.io/badge/Notifications-AWS%20SNS-orange?style=for-the-badge&logo=amazonaws">
</p>


**AMSA Website** is a full-stack web application designed to manage and showcase AMSA activities, events, and member engagement.  
It uses a modern Next.js frontend, a Node.js backend, automated CI/CD pipeline, and secure AWS-based deployment.  

---

## 🚀 Features  

- ⚡ **Fast Frontend**: Next.js for optimized builds and performance  
- 🔧 **Backend API**: Node.js + Express for business logic and APIs  
- 🛠️ **CI/CD Pipeline**: Automated builds and deployments via GitHub Actions  
- 🌍 **CloudFront CDN**: Global delivery of static frontend assets  
- 📊 **Monitoring & Alerts**: Server health and error tracking via AWS CloudWatch  
- ☁️ **AWS Hosting**: Frontend + Backend deployed on AWS EC2  
- 🔐 **Secure by Default**: HTTPS + SSL certificates  

---

## 🗂 Project Structure  

amsa-website/
├── CloudFormation/ # AWS infrastructure templates
├── frontend/ # Next.js frontend
├── backend/ # Node.js backend
├── .github/workflows/ # CI/CD pipeline
└── README.md # Documentation

yaml
Copy code

---

## 🛠️ Tech Stack  

| Component   | Technology                     |
|-------------|--------------------------------|
| Frontend    | Next.js                         |
| Backend     | Node.js, Express               |
| Hosting     | AWS EC2                        |
| CDN         | AWS CloudFront                 |
| CI/CD       | GitHub Actions                 |
| Monitoring  | AWS CloudWatch / Dashboards    |
| Security    | HTTPS / SSL Certificates       |

---

## 🏗️ Architecture Overview  

- **GitHub Actions** → Builds, tests, and deploys frontend + backend  
- **EC2 Instances** → Hosts frontend and backend servers  
- **CloudFront CDN** → Caches frontend for global performance  
- **Monitoring** → Tracks uptime, CPU, memory, network, and errors  

---

## 📦 Deployment Process  

### 1️⃣ CloudFormation (IaC)  
- Spins up EC2 instances for frontend & backend  
- Configures networking, ports, and security groups  
- Sets up CloudFront distribution  

### 2️⃣ CI/CD (GitHub Actions)  
- Triggered on `push` to `main`  
- **Frontend:** Install → Build → Export → Deploy to EC2  
- **Backend:** Install → Deploy with `pm2`  

### 3️⃣ Monitoring & Alerts  
- CloudWatch dashboards for performance  
- Alerts via Email / Slack  

### 4️⃣ Manual Deployment (first time setup)  

**Frontend**
```bash
cd frontend
npm install
npm run build
npm run export

# Copy build to EC2
scp -r out/ ubuntu@<FRONTEND_EC2_IP>:/var/www/frontend-amsa-ajinkya
Backend

bash
Copy code
cd backend
npm install

# Copy backend to EC2
scp -r ./ ubuntu@<BACKEND_EC2_IP>:/home/ubuntu/backend

# SSH into EC2 and start backend
ssh ubuntu@<BACKEND_EC2_IP>
cd backend
pm2 start server.js --name amsa-backend
CloudFront + SSL

Configure CloudFront to serve /out

Attach SSL certificate for HTTPS

🌐 Demo URLs
Frontend (HTTP): http://<FRONTEND_EC2_IP>

Backend API (HTTP): http://<BACKEND_EC2_IP>:3001

(Replace <FRONTEND_EC2_IP> and <BACKEND_EC2_IP> with your actual EC2 public IPs or CloudFront URLs)

💻 Quick Setup Guide
bash
Copy code
# Clone repo
git clone https://github.com/Ajinkya-0599/frontend-amsa-ajinkya.git
cd frontend-amsa-ajinkya

# Frontend
cd frontend
npm install
npm run dev      # Development
npm run build    # Production

# Backend
cd ../backend
npm install
npm start        # Development
pm2 start server.js --name backend  # Production


🏷️ Badges

# 🌟 AMSA Website  


**AMSA** is a full-stack web application designed to manage and showcase AMSA activities, events, and member engagement.  
It uses a modern Next.js frontend, a Node.js backend, automated CI/CD pipeline, and secure AWS-based deployment.  

## 🏷️ Badges  

![Next.js](https://img.shields.io/badge/Frontend-Next.js-black?logo=next.js&logoColor=white)  
![Node.js](https://img.shields.io/badge/Backend-Node.js-green?logo=node.js&logoColor=white)  
![AWS](https://img.shields.io/badge/Cloud-AWS-orange?logo=amazon-aws&logoColor=white)  
![GitHub Actions](https://img.shields.io/badge/CI/CD-GitHub_Actions-black?logo=github&logoColor=white)  

---


📄 License
This project is licensed under the MIT License — see the LICENSE file.

yaml
Copy code

---

### ✅ How to use:

1. Open your repo folder locally.
2. Create or replace the existing `README.md` with this content.
3. Run:

```bash
git add README.md
git commit -m "Update README with modern project overview and deployment details"
git push origin main
Check your repo: https://github.com/Ajinkya-0599/frontend-amsa-ajinkya 
