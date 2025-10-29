# basic image based on original Node.js image
FROM node:18-alpine

# set work dir
WORKDIR /app

# install system dependencies
RUN apk add --no-cache \
    curl \
    base \
    git \
    python3 \
    make \
    g++

# install rust & cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# install solana CLI
RUN sh -c "$(curl -sSfL https://release.solana.com/v1.18.0/install)"
ENV PATH="/root/.local/share/solana/install/active_release/bin:${PATH}"

# install anchor
RUN cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
RUN avm install latest
RUN avm use latest

# copy package.json & yarn.lock
COPY package.json yarn.lock* ./

# install Node.js dependencies
RUN yarn install --frozen-lockfile

# copy project file
COPY . .

# build program
RUN anchor build

# expose port
EXPOSE 3000 8899

# create lancuh script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# launch solana test validator\n\
solana-test-validator --reset &\n\
VALIDATOR_PID=$!\n\
\n\
# waiting for validator launching\n\
sleep 10\n\
\n\
# deploy program\n\
anchor deploy\n\
\n\
# launch frontend server\n\
node scripts/dev-server.js &\n\
SERVER_PID=$!\n\
\n\
# close\n\
trap "kill $VALIDATOR_PID $SERVER_PID" EXIT\n\
\n\
# keep container running\n\
wait\n\
' > /app/start.sh && chmod +x /app/start.sh

# launch cmd
CMD ["/app/start.sh"]