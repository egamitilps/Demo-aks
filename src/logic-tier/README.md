# Logic Tier - .NET Core Web API

This directory will contain the .NET Core Web API logic tier (business logic layer) for the retail store.

## 📦 What Goes Here

- .NET Core Web API project
- Controllers, models, and services
- Entity Framework Core for database access
- Dockerfile for containerization
- Kubernetes manifests (deployments, services)

## 🚀 Planned Tech Stack

- **Framework**: .NET 8 / ASP.NET Core Web API
- **ORM**: Entity Framework Core
- **Database**: Azure SQL Database
- **Authentication**: JWT Bearer Tokens / Azure AD
- **API Documentation**: Swagger/OpenAPI
- **Logging**: Serilog with Azure Log Analytics sink

## 📁 Recommended Structure

```
logic-tier/
├── Controllers/
│   ├── ProductsController.cs
│   ├── OrdersController.cs
│   ├── CustomersController.cs
│   └── AuthController.cs
├── Models/
│   ├── Product.cs
│   ├── Order.cs
│   ├── Customer.cs
│   └── OrderItem.cs
├── Data/
│   ├── ApplicationDbContext.cs
│   └── Migrations/
├── Services/
│   ├── IProductService.cs
│   ├── ProductService.cs
│   └── OrderService.cs
├── DTOs/
│   ├── ProductDto.cs
│   └── OrderDto.cs
├── Middleware/
│   └── ExceptionHandlingMiddleware.cs
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
├── Properties/
│   └── launchSettings.json
├── appsettings.json
├── appsettings.Development.json
├── Program.cs
├── Dockerfile
├── .dockerignore
├── RetailStoreApi.csproj
└── README.md
```

## 🐳 Sample Dockerfile

```dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["RetailStoreApi.csproj", "./"]
RUN dotnet restore "RetailStoreApi.csproj"

# Copy everything else and build
COPY . .
RUN dotnet build "RetailStoreApi.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "RetailStoreApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
EXPOSE 80
EXPOSE 443

COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "RetailStoreApi.dll"]
```

## ☸️ Sample Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logic-tier-deployment
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: logic-tier
  template:
    metadata:
      labels:
        app: logic-tier
    spec:
      containers:
      - name: logic-tier
        image: <acr-name>.azurecr.io/logic-tier:latest
        ports:
        - containerPort: 80
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
        - name: ConnectionStrings__DefaultConnection
          valueFrom:
            secretKeyRef:
              name: sql-connection-string
              key: connection-string
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: logic-tier-service
  namespace: default
spec:
  selector:
    app: logic-tier
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

## 🗄️ Database Models

### Product Model
```csharp
public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
    public string Category { get; set; }
    public string ImageUrl { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
```

### Order Model
```csharp
public class Order
{
    public int Id { get; set; }
    public int CustomerId { get; set; }
    public Customer Customer { get; set; }
    public DateTime OrderDate { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; }
    public ICollection<OrderItem> OrderItems { get; set; }
}
```

### Customer Model
```csharp
public class Customer
{
    public int Id { get; set; }
    public string Email { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string Phone { get; set; }
    public DateTime CreatedAt { get; set; }
    public ICollection<Order> Orders { get; set; }
}
```

## 🔌 API Endpoints

### Products
- `GET /api/products` - Get all products
- `GET /api/products/{id}` - Get product by ID
- `POST /api/products` - Create new product (admin)
- `PUT /api/products/{id}` - Update product (admin)
- `DELETE /api/products/{id}` - Delete product (admin)

### Orders
- `GET /api/orders` - Get user's orders
- `GET /api/orders/{id}` - Get order by ID
- `POST /api/orders` - Create new order
- `PUT /api/orders/{id}/status` - Update order status (admin)

### Customers
- `GET /api/customers/me` - Get current user profile
- `PUT /api/customers/me` - Update user profile
- `POST /api/customers/register` - Register new customer
- `POST /api/customers/login` - Login

### Health
- `GET /health` - Basic health check
- `GET /health/ready` - Readiness check (includes DB connectivity)

## 🔧 Configuration

### appsettings.json
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=tcp:retail-dev-sql.database.windows.net,1433;Initial Catalog=retailDB;..."
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Jwt": {
    "Key": "YourSecretKeyHere",
    "Issuer": "RetailStoreApi",
    "Audience": "RetailStoreClient",
    "ExpiryMinutes": 60
  }
}
```

### Environment Variables (Kubernetes)
```yaml
env:
- name: ASPNETCORE_ENVIRONMENT
  value: "Production"
- name: ConnectionStrings__DefaultConnection
  valueFrom:
    secretKeyRef:
      name: sql-connection-string
      key: connection-string
- name: Jwt__Key
  valueFrom:
    secretKeyRef:
      name: jwt-secret
      key: secret-key
```

## 🏗️ Getting Started

### Prerequisites
```bash
dotnet --version  # .NET 8 SDK or higher
```

### Create New Project
```bash
cd src/logic-tier

# Create new Web API project
dotnet new webapi -n RetailStoreApi
cd RetailStoreApi

# Add required packages
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Tools
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add package Swashbuckle.AspNetCore
dotnet add package Serilog.AspNetCore
dotnet add package Serilog.Sinks.Console

# Restore dependencies
dotnet restore
```

### Database Migrations
```bash
# Create initial migration
dotnet ef migrations add InitialCreate

# Update database
dotnet ef database update

# For production (from local machine with VPN or jump box):
dotnet ef database update --connection "Server=tcp:retail-dev-sql.database.windows.net,1433;..."
```

### Run Locally
```bash
# Development mode
dotnet run

# Watch mode (auto-reload)
dotnet watch run

# Test the API
curl http://localhost:5000/api/products
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
docker build -t ${ACR_NAME}.azurecr.io/logic-tier:latest .

# Push to ACR
docker push ${ACR_NAME}.azurecr.io/logic-tier:latest
```

### Deploy to AKS
```bash
# Create SQL connection secret (if not already created)
kubectl create secret generic sql-connection-string \
  --from-literal=connection-string="Server=tcp:...,1433;..."

# Update k8s manifests with your ACR name
# Then apply:
kubectl apply -f k8s/
```

## 🧪 Testing

### Unit Tests
```bash
# Create test project
dotnet new xunit -n RetailStoreApi.Tests

# Add reference
cd RetailStoreApi.Tests
dotnet add reference ../RetailStoreApi/RetailStoreApi.csproj

# Add test packages
dotnet add package Moq
dotnet add package FluentAssertions
dotnet add package Microsoft.EntityFrameworkCore.InMemory

# Run tests
dotnet test
```

### Integration Tests
```bash
# Create integration test project
dotnet new xunit -n RetailStoreApi.IntegrationTests

# Add Microsoft.AspNetCore.Mvc.Testing
dotnet add package Microsoft.AspNetCore.Mvc.Testing

# Run integration tests
dotnet test
```

## 🔒 Security Best Practices

1. **Secrets Management**: Use Kubernetes secrets or Azure Key Vault
2. **SQL Injection**: Use parameterized queries (EF Core handles this)
3. **Authentication**: Implement JWT authentication
4. **Authorization**: Use role-based access control (RBAC)
5. **HTTPS**: Always use HTTPS in production
6. **Input Validation**: Validate all user inputs
7. **Error Handling**: Don't expose stack traces in production

## 📊 Monitoring & Logging

### Health Checks
```csharp
builder.Services.AddHealthChecks()
    .AddSqlServer(
        connectionString: builder.Configuration.GetConnectionString("DefaultConnection"),
        name: "sql",
        failureStatus: HealthStatus.Degraded,
        tags: new[] { "db", "sql" });

app.MapHealthChecks("/health");
app.MapHealthChecks("/health/ready");
```

### Logging with Serilog
```csharp
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .WriteTo.Console()
    .WriteTo.AzureAnalytics(
        workspaceId: "<workspace-id>",
        authenticationId: "<auth-id>")
    .CreateLogger();
```

## 📚 Resources

- [ASP.NET Core Documentation](https://docs.microsoft.com/aspnet/core)
- [Entity Framework Core](https://docs.microsoft.com/ef/core)
- [Azure SQL Database](https://docs.microsoft.com/azure/azure-sql)
- [JWT Authentication in .NET](https://jwt.io/)

## 🔄 Development Workflow

1. Make code changes
2. Test locally with `dotnet run`
3. Build Docker image
4. Push to ACR
5. Update Kubernetes deployment
6. Verify in AKS cluster

---

**Status**: 🚧 Not yet implemented - placeholder for future development
