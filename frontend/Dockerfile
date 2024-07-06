# Use an official Node runtime as a parent image
FROM node:16

# Set the working directory in the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the current directory contents into the container
COPY . .

# Build the app
RUN npm run build

# Install Vite globally to use it for preview
RUN npm install -g vite

EXPOSE 5173

# Start the app using Vite preview
CMD ["vite", "preview", "--host", "0.0.0.0", "--port", "5173"]