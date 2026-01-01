# Frontend Application - React

This directory will contain the React frontend application for the retail store.

## 📦 What Goes Here

- React application code
- Components, pages, and layouts
- Static assets (images, CSS, fonts)
- Dockerfile for containerization
- Kubernetes manifests (deployments, services, ingress)

## 🚀 Planned Tech Stack

- **Framework**: React 18+
- **Build Tool**: Vite or Create React App
- **Styling**: CSS Modules / Tailwind CSS / Material-UI
- **State Management**: React Context / Redux Toolkit
- **API Client**: Axios / Fetch API
- **Routing**: React Router

## 📁 Recommended Structure

```
frontend/
├── public/
│   ├── index.html
│   └── assets/
├── src/
│   ├── components/
│   │   ├── common/
│   │   ├── layout/
│   │   └── products/
│   ├── pages/
│   │   ├── Home.jsx
│   │   ├── Products.jsx
│   │   ├── Cart.jsx
│   │   └── Checkout.jsx
│   ├── services/
│   │   └── api.js
│   ├── hooks/
│   ├── utils/
│   ├── App.jsx
│   └── main.jsx
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── Dockerfile
├── .dockerignore
├── package.json
└── README.md
```

## 🐳 Sample Dockerfile

```dockerfile
# Build stage
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## ☸️ Sample Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: <acr-name>.azurecr.io/frontend:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: default
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

## 🔌 Backend API Integration

The frontend will call the backend API at:
- **Development**: `http://backend-service/api`
- **Production**: `https://your-domain.com/api`

Environment variables:
```bash
VITE_API_URL=http://backend-service/api
# or
REACT_APP_API_URL=http://backend-service/api
```

## 📋 Features to Implement

### Must-Have Features
- [ ] Product catalog/listing
- [ ] Product detail pages
- [ ] Shopping cart functionality
- [ ] Checkout process
- [ ] User authentication (login/register)
- [ ] Order history

### Nice-to-Have Features
- [ ] Product search and filtering
- [ ] Wishlist
- [ ] Product reviews
- [ ] User profile management
- [ ] Real-time inventory updates

## 🏗️ Getting Started

### Prerequisites
```bash
node --version  # v18 or higher
npm --version   # v9 or higher
```

### Create React App (Example)
```bash
cd src/frontend

# Using Vite (recommended)
npm create vite@latest . -- --template react

# Or using Create React App
npx create-react-app .

# Install dependencies
npm install axios react-router-dom

# Start development server
npm run dev
```

### Build Docker Image
```bash
# Get ACR name
ACR_NAME=$(az deployment group show \
  --resource-group rg-retail-dev \
  --name <deployment-name> \
  --query 'properties.outputs.acrName.value' \
  --output tsv)

# Login to ACR
az acr login --name $ACR_NAME

# Build image
docker build -t ${ACR_NAME}.azurecr.io/frontend:latest .

# Push to ACR
docker push ${ACR_NAME}.azurecr.io/frontend:latest
```

### Deploy to AKS
```bash
# Update k8s manifests with your ACR name
# Then apply:
kubectl apply -f k8s/
```

## 🔧 Development Guidelines

1. **Component Structure**: Use functional components with hooks
2. **Code Style**: Follow Airbnb React style guide
3. **Testing**: Write unit tests with Jest and React Testing Library
4. **Accessibility**: Follow WCAG 2.1 guidelines
5. **Performance**: Optimize bundle size, lazy load routes

## 📚 Resources

- [React Documentation](https://react.dev/)
- [Vite Documentation](https://vitejs.dev/)
- [Material-UI](https://mui.com/)
- [React Router](https://reactrouter.com/)

---

**Status**: 🚧 Not yet implemented - placeholder for future development
