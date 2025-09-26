services:
  mongo:
    image: mongo:latest
    restart: always
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_USERNAME}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
    volumes:
      - mongo_data:/data/db
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "mongo", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 3

  node:
    build:
      context: ./backend
      dockerfile: Dockerfile
    restart: always
    command: sh -c "nodemon --legacy-watch index.js"
    environment:
      MONGO_URI: mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@mongo:27017/myapp?authSource=admin
      NODE_ENV: production
    volumes:
      - ./backend:/app
      - /app/node_modules
    depends_on:
      - mongo
    networks:
      - app-network
    expose:
      - 5000
    ports:
      - "5000:5000"
  react:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    volumes:
      - ./frontend:/app
      - /app/node_modules
    environment:
      CHOKIDAR_USEPOLLING: true
    ports:
      - "3000:3000"
    networks:
      - app-network
  nginx:
      build:
        context: ./frontend
        dockerfile: Dockerfile
      restart: always
      networks:
        - app-network
      ports:
        - "80:80"
      depends_on:
        - node

  wireguard:
    image: ghcr.io/wg-easy/wg-easy
    restart: always
    environment:
      - WG_HOST=vpn.grapevine.co.ke
      - PASSWORD_HASH=$2b$10$Zwk49VV2yoaAVnPSvv2Am.ZQV6YUmaD1vOAHGl8DHtJXrjIXyK9y.
      - WG_PORT=51820
      - WG_DEFAULT_DNS=1.1.1.1
    volumes:
      - wg_data:/etc/wireguard
    # ports:
      # - "51820:51820/udp"
      # - "51821:51821/tcp"  # Restrict in production
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.ip_forward=1
    networks:
      - app-network
      - wg-network

  cloudflared:
      image: cloudflare/cloudflared:latest
      restart: always
      volumes:
        - ./cloudflared/config.yml:/etc/cloudflared/config.yml:ro
        - ./cloudflared/credentials.json:/etc/cloudflared/credentials.json:ro
      command: --no-autoupdate --config /etc/cloudflared/config.yml tunnel run
      networks:
        - app-network
      depends_on:
          - nginx
networks:
  app-network:
    driver: bridge
  wg-network:
    driver: bridge

volumes:
  mongo_data:
  wg_data: