# Frontend - ReactJS with ChakraUI

This directory contains the frontend of the application built with ReactJS and ChakraUI.

## Prerequisites

- Node.js (version 14.x or higher)
- npm (version 6.x or higher)

## Setup Instructions

1. **Navigate to the frontend directory**:
    ```sh
    cd frontend
    ```

2. **Install dependencies**:
    ```sh
    npm install
    ```

3. **Run the development server**:
    ```sh
    npm run dev
    ```

4. **Configure API URL**:
   Ensure the API URL is correctly set in the `.env` file.

### Open Ports

The backend service typically runs on the following ports:

- **8000**: Main FastAPI application (HTTP)
- **5432**: PostgreSQL database (if running locally)

Ensure these ports are open and not in use by other services when running the application.

### API Routes

Here are the main API routes available in the backend:

1. Authentication
    - POST `/api/v1/login/access-token`: Obtain JWT access token
    - POST `/api/v1/login/test-token`: Test if the access token is valid
2. Users
    - GET `/api/v1/users/`: List users (admin only)
    - POST `/api/v1/users/`: Create new user (admin only)
    - GET `/api/v1/users/{user_id}`: Get user by ID
    - PUT `/api/v1/users/{user_id}`: Update user
    - DELETE `/api/v1/users/{user_id}`: Delete user (admin only)
3. Items
    - GET `/api/v1/items/`: List items
    - POST `/api/v1/items/`: Create new item
    - GET `/api/v1/items/{item_id}`: Get item by ID
    - PUT `/api/v1/items/{item_id}`: Update item
    - DELETE `/api/v1/items/{item_id}`: Delete item

### Testing API Routes

You can test these routes using tools like curl, Postman, or the built-in Swagger UI.

1. **Using Swagger UI**:
    - Start the backend server
    - Open a web browser and go to `http://localhost:8000/docs`
    - You can now see all available endpoints and test them directly from the browser
2. **Using curl**: Here are some example curl commands to test the API:
    - Get JWT token:
        
        
        `curl -X POST "http://localhost:8000/api/v1/login/access-token" -H "Content-Type: application/x-www-form-urlencoded" -d "username=admin@example.com&password=admin"`
        
    - List users (replace `{token}` with the JWT token obtained above):
        

        
        `curl -X GET "http://localhost:8000/api/v1/users/" -H "Authorization: Bearer {token}"`
        
    - Create a new item:
        

        
        `curl -X POST "http://localhost:8000/api/v1/items/" -H "Authorization: Bearer {token}" -H "Content-Type: application/json" -d '{"title":"New Item","description":"This is a new item"}'`


        ### Open Ports

The backend service uses the following ports:

- **8000**: Main FastAPI application (HTTP)
- **5432**: PostgreSQL database (if running locally)

To ensure these ports are open and available:

1. Check if the ports are in use:
    
    
    `sudo lsof -i :8000 sudo lsof -i :5432`
    
2. If the ports are in use, you may need to stop the conflicting services or choose different ports for your application.
3. If you're running the application on EC2, ensure these ports are open in your security group settings.

### Testing API Routes

You can test the backend routes using various methods. Here's a detailed guide:

1. **Using Swagger UI**:
    - Start the backend server: `uvicorn app.main:app --reload`
    - Open a web browser and go to `http://localhost:8000/docs`
    - You'll see all available endpoints. Click on an endpoint to expand it.
    - Click "Try it out", fill in any required parameters, and click "Execute" to test the endpoint.
2. **Using curl**: Here are curl commands to test main routes: a. Obtain JWT token:
    
  
    `curl -X POST "http://localhost:8000/api/v1/login/access-token" \      -H "Content-Type: application/x-www-form-urlencoded" \     -d "username=admin@example.com&password=admin"`
    
    Save the returned token for use in subsequent requests. b. List users (admin only):
   
    
    `curl -X GET "http://localhost:8000/api/v1/users/" \      -H "Authorization: Bearer YOUR_TOKEN_HERE"`
    
    c. Create a new item:
    

    
    `curl -X POST "http://localhost:8000/api/v1/items/" \      -H "Authorization: Bearer YOUR_TOKEN_HERE" \     -H "Content-Type: application/json" \     -d '{"title":"New Item","description":"This is a new item"}'`
    
    d. Get a specific item:
    

    
    `curl -X GET "http://localhost:8000/api/v1/items/1" \      -H "Authorization: Bearer YOUR_TOKEN_HERE"`